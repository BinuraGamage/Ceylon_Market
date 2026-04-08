import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'shared/themes/app_theme.dart';
import 'shared/widgets/startup_splash_screen.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'models/notification_model.dart';
import 'models/user_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: SelaMarketApp()));
}

class SelaMarketApp extends ConsumerStatefulWidget {
  const SelaMarketApp({super.key});

  @override
  ConsumerState<SelaMarketApp> createState() => _SelaMarketAppState();
}

class _SelaMarketAppState extends ConsumerState<SelaMarketApp> {
  ProviderSubscription<AsyncValue<User?>>? _authListener;
  ProviderSubscription<AsyncValue<List<NotificationModel>>>?
  _notificationListener;
  static const Duration _startupSplashDuration = Duration(seconds: 3);
  final Set<String> _seenNotificationIds = <String>{};
  bool _notificationsPrimed = false;
  bool _minimumSplashElapsed = false;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _dismissSplashAfterDelay();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FcmService.instance.init();
      _attachRuntimeListeners();

      if (!mounted) return;
      setState(() => _firebaseReady = true);
    } catch (e) {
      debugPrint('[main] Firebase init failed: $e');
      if (!mounted) return;
      // Let the app continue routing even if init has issues,
      // instead of staying forever on a blank startup state.
      setState(() => _firebaseReady = true);
    }
  }

  void _attachRuntimeListeners() {
    _authListener = ref.listenManual<AsyncValue<User?>>(authStateProvider, (
      previous,
      next,
    ) async {
      final previousUid = previous?.value?.uid;
      final firebaseUser = next.value;
      final nextUid = firebaseUser?.uid;

      if (nextUid != null && nextUid.isNotEmpty) {
        // Keep app session persisted by hydrating the Firestore user profile
        // whenever Firebase restores the auth session on app relaunch.
        try {
          final profile = await ref.read(authServiceProvider).getUserById(nextUid);
          if (mounted) {
            ref.read(currentUserProvider.notifier).state = profile;
          }
        } catch (e) {
          debugPrint('[main] Failed to hydrate current user profile: $e');
          if (mounted) {
            // Fallback keeps session usable even if profile fetch is delayed.
            ref.read(currentUserProvider.notifier).state = UserModel(
              uid: nextUid,
              email: firebaseUser?.email ?? '',
              displayName: firebaseUser?.displayName ?? 'User',
              photoUrl: firebaseUser?.photoURL,
              role: 'customer',
              status: 'active',
              createdAt: DateTime.now(),
            );
          }
        }

        await FcmService.instance.refreshTokenForUser(nextUid);
        return;
      }

      if (previousUid != null && previousUid.isNotEmpty) {
        await FcmService.instance.clearTokenForUser(previousUid);
      }

      if (mounted) {
        ref.read(currentUserProvider.notifier).state = null;
      }
    });

    _notificationListener = ref
        .listenManual<AsyncValue<List<NotificationModel>>>(
          notificationsProvider,
          (previous, next) {
            next.whenData((items) async {
              if (!_notificationsPrimed) {
                _seenNotificationIds.addAll(
                  items.map((item) => item.notificationId),
                );
                _notificationsPrimed = true;
                return;
              }

              for (final item in items) {
                if (_seenNotificationIds.contains(item.notificationId)) {
                  continue;
                }
                _seenNotificationIds.add(item.notificationId);
                await FcmService.instance.showLocalNotification(
                  title: item.title,
                  body: item.body,
                );
              }
            });
          },
        );
  }

  void _dismissSplashAfterDelay() {
    Future<void>.delayed(_startupSplashDuration, () {
      if (!mounted) return;
      setState(() => _minimumSplashElapsed = true);
    });
  }

  @override
  void dispose() {
    _authListener?.close();
    _notificationListener?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showStartupSplash = !_minimumSplashElapsed || !_firebaseReady;
    if (showStartupSplash) {
      return MaterialApp(
        title: 'Ceylon Marketplace',
        theme: AppTheme.lightTheme,
        home: const StartupSplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ceylon Marketplace',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
