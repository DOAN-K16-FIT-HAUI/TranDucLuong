import 'package:bloc/bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:finance_app/data/services/local_notification_service.dart';
import 'package:flutter/material.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc(this._repository) : super(NotificationState()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<NotificationReceived>(_onNotificationReceived);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<ScheduleSavingsReminder>(_onScheduleSavingsReminder);
    on<CancelSavingsReminder>(_onCancelSavingsReminder);
    on<LoadSavedReminderSettings>(_onLoadSavedReminderSettings);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.initialize();
    final token = await _repository.getToken();
    debugPrint('FCM Token: $token');

    // Xử lý thông báo foreground
    _repository.getForegroundNotifications().listen((notification) {
      debugPrint(
        'Foreground notification: ${notification.title} - ${notification.body}',
      );
      add(NotificationReceived(notification));
    });

    // Xử lý thông báo background
    _repository.getBackgroundNotifications().listen((notification) {
      add(NotificationReceived(notification));
    });

    // Xử lý thông báo local
    _repository.getLocalNotifications().listen((notification) {
      add(NotificationReceived(notification));
    });

    // Xử lý thông báo khi mở từ terminated
    final initialNotification = await _repository.getInitialNotification();
    if (initialNotification != null) {
      add(NotificationReceived(initialNotification));
    }

    // Load saved reminder settings
    add(LoadSavedReminderSettings());

    emit(state.copyWith(isInitialized: true));
  }

  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final updatedNotifications = List<AppNotification>.from(state.notifications)
      ..add(event.notification);

    // Sort by timestamp (newest first)
    updatedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    emit(state.copyWith(notifications: updatedNotifications));
  }

  void _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) {
    final updated =
        state.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

    emit(state.copyWith(notifications: updated));
  }

  void _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onScheduleSavingsReminder(
    ScheduleSavingsReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.scheduleDailySavingsReminder(
        hour: event.hour,
        minute: event.minute,
        message: event.message,
      );

      // Kiểm tra xem thông báo đã được thiết lập thành công chưa
      final hasScheduled =
          await LocalNotificationService.checkPendingNotificationRequests();

      if (!hasScheduled) {
        debugPrint('WARNING: No pending notifications after scheduling!');
      }

      emit(
        state.copyWith(
          hasActiveReminder: true,
          reminderHour: event.hour,
          reminderMinute: event.minute,
          reminderMessage: event.message,
        ),
      );

      // Add a notification to show in the list
      add(
        NotificationReceived(
          AppNotification.local(
            title: 'Savings Reminder Set',
            body:
                'Daily reminder set for ${_formatTime(event.hour, event.minute)}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');

      // Thông báo lỗi ngay lập tức để người dùng biết
      add(
        NotificationReceived(
          AppNotification.local(
            title: 'Error Setting Reminder',
            body: 'Could not set reminder: ${e.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _onCancelSavingsReminder(
    CancelSavingsReminder event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.cancelAllNotifications();
    emit(state.copyWith(hasActiveReminder: false));

    // Add a notification to show in the list
    add(
      NotificationReceived(
        AppNotification.local(
          title: 'Reminders Cancelled',
          body: 'All scheduled reminders have been cancelled',
        ),
      ),
    );
  }

  Future<void> _onLoadSavedReminderSettings(
    LoadSavedReminderSettings event,
    Emitter<NotificationState> emit,
  ) async {
    final settings = await _repository.getSavedReminderSettings();
    if (settings != null) {
      emit(
        state.copyWith(
          hasActiveReminder: true,
          reminderHour: settings['hour'],
          reminderMinute: settings['minute'],
          reminderMessage: settings['message'],
        ),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
