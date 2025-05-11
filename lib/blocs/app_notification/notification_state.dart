import 'package:finance_app/data/models/app_notification.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isInitialized;
  final bool hasActiveReminder;
  final int? reminderHour;
  final int? reminderMinute;
  final String? reminderMessage;

  NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
    this.hasActiveReminder = false,
    this.reminderHour,
    this.reminderMinute,
    this.reminderMessage,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isInitialized,
    bool? hasActiveReminder,
    int? reminderHour,
    int? reminderMinute,
    String? reminderMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      hasActiveReminder: hasActiveReminder ?? this.hasActiveReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderMessage: reminderMessage ?? this.reminderMessage,
    );
  }
}
