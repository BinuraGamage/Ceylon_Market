import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firestore_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'default_high',
    'General Notifications',
    description: 'General updates and alerts',
    importance: Importance.high,
  );

  StreamSubscription<String>? _tokenSubscription;
  String? _activeUid;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(settings);

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(_channel);
      }

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _initialized = true;
    } catch (e) {
      debugPrint('[FcmService] init error: $e');
    }
  }

  Future<void> refreshTokenForUser(String uid) async {
    try {
      _activeUid = uid;
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await FirestoreService.instance.updateUserFcmToken(
          uid: uid,
          token: token,
        );
      }

      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) async {
        if (_activeUid == null || newToken.isEmpty) return;
        try {
          await FirestoreService.instance.updateUserFcmToken(
            uid: _activeUid!,
            token: newToken,
          );
        } catch (e) {
          debugPrint('[FcmService] onTokenRefresh error: $e');
        }
      });
    } catch (e) {
      debugPrint('[FcmService] refreshTokenForUser error: $e');
    }
  }

  Future<void> clearTokenForUser(String uid) async {
    try {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _activeUid = null;
      await FirestoreService.instance.updateUserFcmToken(uid: uid, token: null);
    } catch (e) {
      debugPrint('[FcmService] clearTokenForUser error: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      await showLocalNotification(
        title: notification.title,
        body: notification.body,
        payload: message.data['route'] as String?,
      );
    } catch (e) {
      debugPrint('[FcmService] showForegroundNotification error: $e');
    }
  }

  Future<void> showLocalNotification({
    required String? title,
    required String? body,
    String? payload,
  }) async {
    try {
      if (!_initialized) {
        await init();
      }

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[FcmService] showLocalNotification error: $e');
    }
  }
}
