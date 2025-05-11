import 'dart:async';

import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:finance_app/data/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepository {
  final FirebaseMessagingService _messagingService;
  final StreamController<AppNotification> _localNotificationController =
      StreamController<AppNotification>.broadcast();

  NotificationRepository(this._messagingService);

  Future<void> initialize() async {
    // Initialize Firebase Messaging
    await _messagingService.initialize();

    // Initialize Local Notifications
    await LocalNotificationService.initialize();

    // Listen to local notification clicks
    LocalNotificationService.onNotificationClick.addListener(() {
      final payload = LocalNotificationService.onNotificationClick.value;
      if (payload != null) {
        if (payload == 'savings_reminder') {
          _localNotificationController.add(
            AppNotification.savingsReminder('Time to set aside some savings!'),
          );
        } else if (payload == 'spending_alert') {
          _localNotificationController.add(
            AppNotification.spendingAlert(
              'You have exceeded your spending limit',
            ),
          );
        }
      }
    });
  }

  // Schedule daily savings reminder
  Future<void> scheduleDailySavingsReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    await LocalNotificationService.scheduleDailySavingsReminder(
      hour: hour,
      minute: minute,
      title: 'Savings Reminder',
      body: message,
    );

    // Save settings to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    await prefs.setString('reminder_message', message);
  }

  // Get saved reminder settings
  Future<Map<String, dynamic>?> getSavedReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('reminder_hour')) {
      return {
        'hour': prefs.getInt('reminder_hour'),
        'minute': prefs.getInt('reminder_minute'),
        'message': prefs.getString('reminder_message'),
      };
    }
    return null;
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await LocalNotificationService.cancelAllNotifications();
  }

  Future<String?> getToken() async {
    return await _messagingService.getToken();
  }

  Stream<AppNotification> getForegroundNotifications() {
    final controller = StreamController<AppNotification>();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      controller.add(AppNotification.fromRemoteMessage(message.toMap()));
    });

    return controller.stream;
  }

  Stream<AppNotification> getLocalNotifications() {
    return _localNotificationController.stream;
  }

  Stream<AppNotification> getBackgroundNotifications() async* {
    await for (final message in FirebaseMessaging.onMessageOpenedApp) {
      yield AppNotification.fromRemoteMessage({
        'messageId': message.messageId,
        'notification': message.notification?.toMap(),
        'data': message.data,
      });
    }
  }

  Future<AppNotification?> getInitialNotification() async {
    final initialMessage = await _messagingService.getInitialMessage();
    if (initialMessage != null) {
      return AppNotification.fromRemoteMessage({
        'messageId': initialMessage.messageId,
        'notification': initialMessage.notification?.toMap(),
        'data': initialMessage.data,
      });
    }
    return null;
  }

  void dispose() {
    _localNotificationController.close();
  }
}
