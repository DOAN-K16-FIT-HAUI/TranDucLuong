import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => NotificationBloc(
            NotificationRepository(FirebaseMessagingService()),
          )..add(InitializeNotifications()),
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        appBar: CommonWidgets.buildAppBar(
          context: context,
          title: 'Thông báo',
          onBackPressed: () => AppRoutes.navigateToDashboard(context),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    Icons.done_all,
                    color: AppTheme.lightTheme.colorScheme.surface,
                  ),
                  tooltip: 'Đánh dấu tất cả là đã đọc',
                  onPressed:
                      () => context.read<NotificationBloc>().add(
                        MarkAllNotificationsAsRead(),
                      ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (!state.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.notifications.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có thông báo nào',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(
                      153,
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _buildNotificationCard(context, notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
  ) {
    final isRead = notification.isRead;
    final colorScheme = AppTheme.lightTheme.colorScheme;

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notification.id),
          );
        }
      },
      child: CommonWidgets.buildItemCard(
        context: context,
        item: notification,
        itemKey: ValueKey(notification.id),
        title: notification.title,
        value: 0,
        icon: Icons.notifications,
        iconColor: colorScheme.primary,
        margin: const EdgeInsets.only(top: 8),
        subtitle: Text(
          notification.body,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color:
                isRead
                    ? colorScheme.onSurface.withAlpha(153)
                    : colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor:
            isRead ? colorScheme.surface : colorScheme.primary.withAlpha(13),
      ),
    );
  }
}
