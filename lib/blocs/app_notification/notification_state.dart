import 'package:finance_app/data/models/app_notification.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isInitialized;

  NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isInitialized,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}