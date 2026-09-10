import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Top-level background message handler for when app is killed or backgrounded
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    // If received as data-only while app is closed/killed, show heads-up notification with sound & vibration
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title']?.toString() ?? 'EasyRead Update';
      final body = message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        final fln = FlutterLocalNotificationsPlugin();
        const channel = AndroidNotificationChannel(
          'easyread_alerts',
          'EasyRead Notifications',
          description: 'Announcements, new books, and reading alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await fln.show(
          id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    }
  } catch (_) {}
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Callback triggered when an administrative deactivation or deletion notice is received via FCM push
  static void Function(String action, String message)? onDeactivationReceived;
  
  // High-importance channel for WhatsApp-like heads-up banner, loud sound and vibration
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'easyread_alerts', // Fresh channel ID forces Android to create channel with MAX sound & vibration
    'EasyRead Notifications',
    description: 'Announcements, new books, and reading alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static Future<void> initialize() async {
    // Only supported on mobile (Android / iOS)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      // 1. Initialize Firebase App
      await Firebase.initializeApp();

      // 2. Set background message handler (Runs even when app is killed)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request Notification Permissions (critical for Android 13+ & iOS)
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // 4. Create high-importance Android Notification Channel with Sound & Vibration
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(_channel);
          await androidPlugin.requestNotificationsPermission();
        }
      }

      // 5. Initialize Local Notifications Plugin for foreground banners
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          requestBadgePermission: true,
        ),
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Tap on notification
        },
      );

      // 6. Set foreground presentation options (shows heads-up notification while app is open)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 7. Subscribe to global topics for instant broadcast (WhatsApp-style)
      try {
        await messaging.subscribeToTopic('all_users');
        await messaging.subscribeToTopic('new_books');
      } catch (e) {
        debugPrint('Push notification topic subscription notice: $e');
      }

      // 8. Register device FCM token with backend
      try {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('FCM Device Token: $token');
          await ApiService.registerDeviceFcmToken(token);
        }
      } catch (e) {
        debugPrint('FCM token retrieval notice: $e');
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Device Token refreshed: $newToken');
        ApiService.registerDeviceFcmToken(newToken);
      });

      // 9. Handle Foreground Messages (when app is currently open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString() ?? 'EasyRead';
        final body = notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';

        final action = message.data['action']?.toString() ?? message.data['type']?.toString() ?? '';
        if (action == 'account_deleted' || action == 'account_suspended') {
          onDeactivationReceived?.call(action, body.isNotEmpty ? body : title);
        }

        _localNotifications.show(
          id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      });

      // 10. Handle Notification Click when opened from Background or Terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification click: ${message.data}');
        final action = message.data['action']?.toString() ?? message.data['type']?.toString() ?? '';
        if (action == 'account_deleted' || action == 'account_suspended') {
          final msg = message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
          onDeactivationReceived?.call(action, msg);
        }
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated notification: ${initialMessage.data}');
        final action = initialMessage.data['action']?.toString() ?? initialMessage.data['type']?.toString() ?? '';
        if (action == 'account_deleted' || action == 'account_suspended') {
          final msg = initialMessage.data['body']?.toString() ?? initialMessage.data['message']?.toString() ?? '';
          onDeactivationReceived?.call(action, msg);
        }
      }
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  /// Explicitly re-sync device FCM token with backend when user logs in
  static Future<void> syncDeviceToken() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.registerDeviceFcmToken(token);
      }
    } catch (_) {}
  }
}

