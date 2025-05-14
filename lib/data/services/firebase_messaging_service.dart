import 'package:finance_app/data/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Check connectivity first but don't block initialization on connectivity errors
    bool isConnected = true;
    try {
      isConnected = await LocalNotificationService.checkConnectivity();
      if (!isConnected) {
        debugPrint(
          'No network connection, FCM initialization will continue but might fail',
        );
        // Continue anyway - don't return early
      }
    } catch (e) {
      debugPrint('Error checking connectivity, continuing anyway: $e');
      // Continue initialization despite connectivity check errors
    }

    // Request permission
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'Firebase messaging permission status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('Error requesting FCM permission: $e');
      await LocalNotificationService.showErrorNotification(
        title: 'Notification Setup Issue',
        body:
            'Could not set up push notifications. Some features may be limited.',
      );
    }

    // Configure message handling
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');

    // First check if we have a notification payload
    if (message.notification != null) {
      final data = message.data;
      int notificationId;

      // Determine notification type and ID
      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'spending_alert':
            notificationId =
                LocalNotificationService.spendingAlertNotificationId;
            break;
          case 'savings_reminder':
            notificationId =
                LocalNotificationService.savingsReminderNotificationId;
            break;
          default:
            notificationId =
                DateTime.now().millisecond; // Random ID for other types
        }
      } else {
        notificationId = DateTime.now().millisecond;
      }

      // Show local notification for all messages with notification payload
      await LocalNotificationService.showNotification(
        id: notificationId,
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? 'You have a new notification',
        payload:
            data.containsKey('type') ? data['type'] : 'general_notification',
      );
    }
  }

  Future<String?> getToken() async {
    // Try to get token regardless of connectivity
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _messaging.getInitialMessage();
    } catch (e) {
      debugPrint('Error getting initial message: $e');
      return null;
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No implementation needed as we're handling via the background handler in main.dart
}
