import 'package:bloc/bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:flutter/material.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc(this._repository) : super(NotificationState()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<NotificationReceived>(_onNotificationReceived);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
  }

  Future<void> _onInitializeNotifications(
      InitializeNotifications event, Emitter<NotificationState> emit) async {
    await _repository.initialize();
    final token = await _repository.getToken();
    debugPrint('FCM Token: $token');

    // Xử lý thông báo foreground
    _repository.getForegroundNotifications().listen((notification) {
      debugPrint('Foreground notification: ${notification.title} - ${notification.body}');
      add(NotificationReceived(notification));
    });

    // Xử lý thông báo background
    _repository.getBackgroundNotifications().listen((notification) {
      add(NotificationReceived(notification));
    });

    // Xử lý thông báo khi mở từ terminated
    final initialNotification = await _repository.getInitialNotification();
    if (initialNotification != null) {
      add(NotificationReceived(initialNotification));
    }

    emit(state.copyWith(isInitialized: true));
  }

  void _onNotificationReceived(
      NotificationReceived event, Emitter<NotificationState> emit) {
    final updatedNotifications = List<AppNotification>.from(state.notifications)
      ..add(event.notification);
    emit(state.copyWith(notifications: updatedNotifications));
  }

  void _onMarkNotificationAsRead(
      MarkNotificationAsRead event, Emitter<NotificationState> emit) {
    final updated = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    emit(state.copyWith(notifications: updated));
  }

  void _onMarkAllNotificationsAsRead(
      MarkAllNotificationsAsRead event, Emitter<NotificationState> emit) {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    emit(state.copyWith(notifications: updated));
  }
}