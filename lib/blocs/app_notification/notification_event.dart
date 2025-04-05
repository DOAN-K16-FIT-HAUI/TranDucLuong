import 'package:finance_app/data/models/app_notification.dart';

abstract class NotificationEvent {}

class InitializeNotifications extends NotificationEvent {}

class NotificationReceived extends NotificationEvent {
  final AppNotification notification;

  NotificationReceived(this.notification);
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  MarkNotificationAsRead(this.notificationId);
}

class MarkAllNotificationsAsRead extends NotificationEvent {}
