import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'shared/themes/app_theme.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: SelaMarketApp()));
}

class SelaMarketApp extends ConsumerStatefulWidget {
  const SelaMarketApp({super.key});

  @override
  ConsumerState<SelaMarketApp> createState() => _SelaMarketAppState();
}

class _SelaMarketAppState extends ConsumerState<SelaMarketApp> {
  late final ProviderSubscription<AsyncValue<User?>> _authListener;
  late final ProviderSubscription<AsyncValue<List<NotificationModel>>>
  _notificationListener;
  final Set<String> _seenNotificationIds = <String>{};
  bool _notificationsPrimed = false;

  @override
  void initState() {
    super.initState();
    FcmService.instance.init();

    _authListener = ref.listenManual<AsyncValue<User?>>(authStateProvider, (
      previous,
      next,
    ) async {
      final previousUid = previous?.value?.uid;
      final nextUid = next.value?.uid;

      if (nextUid != null && nextUid.isNotEmpty) {
        await FcmService.instance.refreshTokenForUser(nextUid);
        return;
      }

      if (previousUid != null && previousUid.isNotEmpty) {
        await FcmService.instance.clearTokenForUser(previousUid);
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
                if (_seenNotificationIds.contains(item.notificationId))
                  continue;
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

  @override
  void dispose() {
    _authListener.close();
    _notificationListener.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ceylon Marketplace',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
