import 'dart:async';

import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationRepository {
  final FirebaseMessagingService _messagingService;

  NotificationRepository(this._messagingService);

  Future<void> initialize() async {
    await _messagingService.initialize();
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
}