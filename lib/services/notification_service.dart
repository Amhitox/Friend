import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../config/firebase_config.dart';

/// Notification channels used by the app.
class NotificationChannels {
  static const dailyCheckIn = 'daily_checkin';
  static const engagement = 'engagement';
  static const subscription = 'subscription';
  static const system = 'system';
}

/// Notification service for Dostok.
///
/// Combines Firebase Cloud Messaging (FCM) for push notifications with
/// `flutter_local_notifications` for scheduled local notifications.
///
/// Features:
///   - Daily check-in at user preferred time
///   - Engagement nudges ("Dostok misses you!")
///   - Limit-reset alerts
///   - Trial-expiring warnings
///   - Quiet hours (10 PM - 8 AM default)
///   - Topic subscriptions for broadcast messages
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Callback set by the app to handle notification taps.
  /// Receives the notification payload string.
  void Function(String? payload)? onTap;

  /// Quiet hours boundaries (24-hour format). No notifications are sent
  /// between [quietStart] and [quietEnd].
  int quietStart = 22; // 10 PM
  int quietEnd = 8; // 8 AM

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Request permissions, configure local notification channels, and set up
  /// FCM message handlers.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      await _requestPermissions();
      await _configureLocalNotifications();
      await _configureFCM();
      await _subscribeToDefaultTopics();

      _initialized = true;
      if (kDebugMode) {
        debugPrint('[NotificationService] Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Initialization failed: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else if (Platform.isAndroid) {
      // Android 13+ requires runtime permission.
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // handled via FCM above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        onTap?.call(details.payload);
      },
    );

    // Create Android notification channels.
    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.dailyCheckIn,
      'Daily Check-in',
      description: 'Morning reminder to practice Darija',
      importance: Importance.high,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.engagement,
      'Engagement',
      description: 'Friendly nudges to keep practicing',
      importance: Importance.defaultImportance,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.subscription,
      'Subscription',
      description: 'Trial and subscription updates',
      importance: Importance.high,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.system,
      'System',
      description: 'System notifications',
      importance: Importance.low,
    ));
  }

  Future<void> _configureFCM() async {
    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background tap.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageTap(message);
    });

    // App launched from terminated state via notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly so the app has time to set up navigation.
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageTap(initialMessage);
      });
    }
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      await _messaging.subscribeToTopic(FirebaseConfig.topicBroadcast);
      await _messaging.subscribeToTopic(FirebaseConfig.topicEngagement);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Topic subscription failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Topic subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribe to an FCM topic for targeted broadcast messages.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] subscribeToTopic($topic) failed: $e');
      }
    }
  }

  /// Unsubscribe from an FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] unsubscribeFromTopic($topic) failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Local notifications
  // ---------------------------------------------------------------------------

  /// Schedule a daily check-in notification at [hour]:[minute].
  ///
  /// Default is 9:00 AM. Respects quiet hours -- if the scheduled time falls
  /// within quiet hours the notification is skipped.
  Future<void> scheduleDailyCheckIn({
    int hour = 9,
    int minute = 0,
  }) async {
    if (_isQuietHour(hour)) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Skipping check-in at $hour:$minute -- quiet hours');
      }
      return;
    }

    await _cancelNotification(_NotificationIds.dailyCheckIn);

    await _localNotifications.zonedSchedule(
      _NotificationIds.dailyCheckIn,
      'Sbah lkhir! ☀️',
      'Waxxa nbdaw ntmarnaw darija lyom?',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.dailyCheckIn,
          'Daily Check-in',
          channelDescription: 'Morning reminder to practice Darija',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_checkin',
    );

    if (kDebugMode) {
      debugPrint('[NotificationService] Scheduled daily check-in at $hour:$minute');
    }
  }

  /// "Dostok misses you! 3ndou message jdid."
  ///
  /// Shown when the user has been inactive for a while.
  Future<void> sendEngagementNotification() async {
    if (_isQuietHour(DateTime.now().hour)) return;

    await _showNotification(
      id: _NotificationIds.engagement,
      title: 'Dostok misses you! 🥺',
      body: '3ndou message jdid. Raj3 3andou!',
      channel: NotificationChannels.engagement,
      payload: 'engagement',
    );
  }

  /// "Messages dyalek resetaw! 3andek 20 message jdod."
  ///
  /// Shown when the daily message limit resets.
  Future<void> sendLimitResetNotification({int messageCount = 20}) async {
    if (_isQuietHour(DateTime.now().hour)) return;

    await _showNotification(
      id: _NotificationIds.limitReset,
      title: 'Messages resetaw! ✨',
      body: '3andek $messageCount message jdod. Bda nhar bjdid!',
      channel: NotificationChannels.subscription,
      payload: 'limit_reset',
    );
  }

  /// "Trial dyalek ghadi ysali ghdda!"
  ///
  /// Shown when the free trial is about to expire.
  Future<void> sendTrialExpiringNotification() async {
    if (_isQuietHour(DateTime.now().hour)) return;

    await _showNotification(
      id: _NotificationIds.trialExpiring,
      title: 'Trial ghadi ysali! ⏰',
      body: 'Trial dyalek ghadi ysali ghdda. Subscribe bach tkml!',
      channel: NotificationChannels.subscription,
      payload: 'trial_expiring',
    );
  }

  /// Show a generic local notification.
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            _channelDisplayName(channel),
            channelDescription: _channelDescription(channel),
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] showNotification failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // FCM message handlers
  // ---------------------------------------------------------------------------

  /// Handle a message arriving while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[NotificationService] Foreground message: ${message.messageId}');
    }

    final notification = message.notification;
    if (notification == null) return;

    // Show as a local notification so the user sees it.
    _showNotification(
      id: message.hashCode,
      title: notification.title ?? 'Dostok',
      body: notification.body ?? '',
      channel: _inferChannel(message),
      payload: message.data['route'],
    );
  }

  /// Handle a notification tap (from background or terminated state).
  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[NotificationService] Notification tap: ${message.messageId}');
    }
    onTap?.call(message.data['route'] as String?);
  }

  // ---------------------------------------------------------------------------
  // Quiet hours
  // ---------------------------------------------------------------------------

  /// Returns `true` if [hour] falls within the quiet window.
  bool _isQuietHour(int hour) {
    if (quietStart <= quietEnd) {
      // Simple range, e.g. 0-8
      return hour >= quietStart && hour < quietEnd;
    } else {
      // Wrapping range, e.g. 22-8
      return hour >= quietStart || hour < quietEnd;
    }
  }

  // ---------------------------------------------------------------------------
  // Scheduling helpers
  // ---------------------------------------------------------------------------

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  // ---------------------------------------------------------------------------
  // Channel helpers
  // ---------------------------------------------------------------------------

  String _channelDisplayName(String channel) {
    switch (channel) {
      case NotificationChannels.dailyCheckIn:
        return 'Daily Check-in';
      case NotificationChannels.engagement:
        return 'Engagement';
      case NotificationChannels.subscription:
        return 'Subscription';
      case NotificationChannels.system:
        return 'System';
      default:
        return 'Dostok';
    }
  }

  String _channelDescription(String channel) {
    switch (channel) {
      case NotificationChannels.dailyCheckIn:
        return 'Morning reminder to practice Darija';
      case NotificationChannels.engagement:
        return 'Friendly nudges to keep practicing';
      case NotificationChannels.subscription:
        return 'Trial and subscription updates';
      case NotificationChannels.system:
        return 'System notifications';
      default:
        return '';
    }
  }

  String _inferChannel(RemoteMessage message) {
    final type = message.data['type'] as String? ?? '';
    if (type.contains('subscription') || type.contains('trial')) {
      return NotificationChannels.subscription;
    }
    if (type.contains('engagement')) {
      return NotificationChannels.engagement;
    }
    return NotificationChannels.system;
  }
}

/// Stable notification IDs used with `flutter_local_notifications`.
abstract class _NotificationIds {
  static const dailyCheckIn = 1001;
  static const engagement = 1002;
  static const limitReset = 1003;
  static const trialExpiring = 1004;
}
