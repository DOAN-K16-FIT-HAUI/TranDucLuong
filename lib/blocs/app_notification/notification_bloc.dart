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
    // If we're reinitializing (already initialized), emit loading state
    if (state.isInitialized) {
      emit(state.copyWith(isInitialized: false));
    }

    await _repository.initialize();

    // Load saved notifications first
    final savedNotifications = await _repository.getSavedNotifications();

    // Check FCM token but don't block on failure
    try {
      final token = await _repository.getToken();
      debugPrint('FCM Token: ${token ?? "null - will retry later"}');

      if (token == null) {
        // Schedule a token retry for later
        Future.delayed(const Duration(seconds: 30), () async {
          final retryToken = await _repository.getToken();
          debugPrint('Retry FCM Token: ${retryToken ?? "still null"}');
        });
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

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
      _repository.saveNotification(notification);
    });

    // Xử lý thông báo khi mở từ terminated
    final initialNotification = await _repository.getInitialNotification();
    if (initialNotification != null) {
      add(NotificationReceived(initialNotification));
    }

    // Load saved reminder settings
    add(LoadSavedReminderSettings());

    // Emit the new state with loaded notifications
    emit(
      state.copyWith(isInitialized: true, notifications: savedNotifications),
    );
  }

  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final updatedNotifications = List<AppNotification>.from(state.notifications)
      ..add(event.notification);

    // Sort by timestamp (newest first)
    updatedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Save the notification to persistent storage
    _repository.saveNotification(event.notification);

    emit(state.copyWith(notifications: updatedNotifications));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updated =
        state.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

    // Update in persistent storage
    await _repository.markNotificationAsRead(event.notificationId);

    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    // Update in persistent storage
    await _repository.markAllNotificationsAsRead();

    emit(state.copyWith(notifications: updated));
  }

  Future<void> _onScheduleSavingsReminder(
    ScheduleSavingsReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Check permissions first
      final hasPermission =
          await LocalNotificationService.checkPermissionStatus();
      if (!hasPermission) {
        add(
          NotificationReceived(
            AppNotification.local(
              title: 'Permission Required',
              body:
                  'Please enable notifications in your device settings to receive reminders.',
              payload: 'permission_alert',
            ),
          ),
        );
        return;
      }

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
        add(
          NotificationReceived(
            AppNotification.local(
              title: 'Reminder Setup Issue',
              body:
                  'The reminder may not work correctly. Please check your device settings.',
              payload: 'setup_alert',
            ),
          ),
        );
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
            payload: 'reminder_confirmation',
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
            body:
                'Could not set reminder. Please check notification permissions.',
            payload: 'error_alert',
          ),
        ),
      );
    }
  }

  Future<void> _onCancelSavingsReminder(
    CancelSavingsReminder event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.cancelSavingsReminder();
    emit(state.copyWith(hasActiveReminder: false));

    // Add a notification to show in the list
    add(
      NotificationReceived(
        AppNotification.local(
          title: 'Reminders Cancelled',
          body: 'Savings reminder has been cancelled',
          payload: 'cancel_confirmation',
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
