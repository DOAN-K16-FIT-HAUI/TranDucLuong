import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/services/local_notification_service.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Configure message handling
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');

    // Check if message contains spending alert
    final data = message.data;
    if (data.containsKey('type') && data['type'] == 'spending_alert') {
      // Show immediate local notification for spending alerts
      await LocalNotificationService.showNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'Spending Alert',
        body:
            message.notification?.body ??
            'You have exceeded your spending limit',
        payload: 'spending_alert',
      );
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No implementation needed as we're handling via the background handler in main.dart
}
