import 'dart:async';
import 'dart:convert';

import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:finance_app/data/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepository {
  final FirebaseMessagingService _messagingService;
  final StreamController<AppNotification> _localNotificationController =
      StreamController<AppNotification>.broadcast();

  static const String _notificationsStorageKey = 'saved_notifications';
  static const int _maxStoredNotifications = 50; // Limit stored notifications

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

  // Schedule daily savings reminder with permission check
  Future<void> scheduleDailySavingsReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    try {
      final hasPermission =
          await LocalNotificationService.checkPermissionStatus();
      if (!hasPermission) {
        throw Exception('Notification permission not granted');
      }

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
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
      // Show an error message to the user
      await LocalNotificationService.showErrorNotification(
        title: 'Reminder Setup Failed',
        body: 'Please check notification permissions in settings.',
      );
      rethrow;
    }
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

  // Cancel specific notification instead of all
  Future<void> cancelSavingsReminder() async {
    await LocalNotificationService.cancelNotification(
      LocalNotificationService.savingsReminderNotificationId,
    );

    // Remove saved settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_hour');
    await prefs.remove('reminder_minute');
    await prefs.remove('reminder_message');
  }

  // Save notifications to persistent storage
  Future<void> saveNotification(AppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications or create empty list
      List<String> savedNotifications =
          prefs.getStringList(_notificationsStorageKey) ?? [];

      // Add new notification as JSON string
      final notificationJson = jsonEncode({
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
        'timestamp': notification.timestamp.toIso8601String(),
        'isRead': notification.isRead,
        'type': notification.type.toString(),
        'data': notification.data,
      });

      savedNotifications.insert(
        0,
        notificationJson,
      ); // Add at beginning (newest first)

      // Limit the number of stored notifications
      if (savedNotifications.length > _maxStoredNotifications) {
        savedNotifications = savedNotifications.sublist(
          0,
          _maxStoredNotifications,
        );
      }

      // Save back to SharedPreferences
      await prefs.setStringList(_notificationsStorageKey, savedNotifications);
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // Get all saved notifications
  Future<List<AppNotification>> getSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotifications =
          prefs.getStringList(_notificationsStorageKey) ?? [];

      return savedNotifications.map((jsonString) {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        return AppNotification(
          id: data['id'],
          title: data['title'],
          body: data['body'],
          timestamp: DateTime.parse(data['timestamp']),
          isRead: data['isRead'] ?? false,
          type:
              data['type']!.toString().contains('local')
                  ? NotificationType.local
                  : NotificationType.cloud,
          data: data['data'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading saved notifications: $e');
      return [];
    }
  }

  // Update notification read status
  Future<void> markNotificationAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotifications =
          prefs.getStringList(_notificationsStorageKey) ?? [];

      final updatedNotifications =
          savedNotifications.map((jsonString) {
            final Map<String, dynamic> data = jsonDecode(jsonString);
            if (data['id'] == id) {
              data['isRead'] = true;
              return jsonEncode(data);
            }
            return jsonString;
          }).toList();

      await prefs.setStringList(_notificationsStorageKey, updatedNotifications);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotifications =
          prefs.getStringList(_notificationsStorageKey) ?? [];

      final updatedNotifications =
          savedNotifications.map((jsonString) {
            final Map<String, dynamic> data = jsonDecode(jsonString);
            data['isRead'] = true;
            return jsonEncode(data);
          }).toList();

      await prefs.setStringList(_notificationsStorageKey, updatedNotifications);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<String?> getToken() async {
    return await _messagingService.getToken();
  }

  Stream<AppNotification> getForegroundNotifications() {
    final controller = StreamController<AppNotification>();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = AppNotification.fromRemoteMessage(message.toMap());
      saveNotification(notification); // Save to persistent storage
      controller.add(notification);
    });

    return controller.stream;
  }

  Stream<AppNotification> getLocalNotifications() {
    return _localNotificationController.stream;
  }

  Stream<AppNotification> getBackgroundNotifications() async* {
    await for (final message in FirebaseMessaging.onMessageOpenedApp) {
      final notification = AppNotification.fromRemoteMessage({
        'messageId': message.messageId,
        'notification': message.notification?.toMap(),
        'data': message.data,
      });
      await saveNotification(notification); // Save to persistent storage
      yield notification;
    }
  }

  Future<AppNotification?> getInitialNotification() async {
    final initialMessage = await _messagingService.getInitialMessage();
    if (initialMessage != null) {
      final notification = AppNotification.fromRemoteMessage({
        'messageId': initialMessage.messageId,
        'notification': initialMessage.notification?.toMap(),
        'data': initialMessage.data,
      });
      await saveNotification(notification); // Save initial notification
      return notification;
    }
    return null;
  }

  void dispose() {
    _localNotificationController.close();
  }
}
