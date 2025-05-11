import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/app_notification.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create:
          (context) => NotificationBloc(
            NotificationRepository(FirebaseMessagingService()),
          )..add(InitializeNotifications()),
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        appBar: AppBarTabBar.buildAppBar(
          context: context,
          title: l10n.notificationsTitle,
          onBackPressed: () => context.pop(),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    Icons.done_all,
                    color: AppTheme.lightTheme.colorScheme.surface,
                  ),
                  tooltip: l10n.notificationsTooltipMarkAllRead,
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
              return Center(
                child: UtilityWidgets.buildLoadingIndicator(context: context),
              );
            }

            return Column(
              children: [
                // Savings Reminder Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.savings, color: Colors.white),
                      ),
                      title: Text(
                        l10n.savingsReminderCardTitle,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        state.hasActiveReminder
                            ? '${l10n.activeReminderAt} ${_formatTime(state.reminderHour!, state.reminderMinute!)}'
                            : l10n.tapToSetupReminderText,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppRoutes.navigateToSavingsReminder(context);
                      },
                    ),
                  ),
                ),

                // Notifications List Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.recentNotificationsHeader,
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (state.notifications.isNotEmpty)
                        Text(
                          '${state.notifications.length} ${l10n.notificationsCount}',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

                // Notification List
                Expanded(
                  child:
                      state.notifications.isEmpty
                          ? Center(
                            child: Text(
                              l10n.notificationsEmptyMessage,
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withAlpha(153),
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: state.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = state.notifications[index];
                              return _buildNotificationCard(
                                context,
                                notification,
                              );
                            },
                          ),
                ),
              ],
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

    // Use different icons based on notification type
    IconData notificationIcon;
    Color iconColor;

    if (notification.type == NotificationType.local) {
      if (notification.data != null &&
          notification.data!['payload'] == 'savings_reminder') {
        notificationIcon = Icons.savings;
        iconColor = Colors.green;
      } else if (notification.data != null &&
          notification.data!['payload'] == 'spending_alert') {
        notificationIcon = Icons.warning;
        iconColor = Colors.orange;
      } else {
        notificationIcon = Icons.message;
        iconColor = Colors.blue;
      }
    } else {
      notificationIcon = Icons.notifications;
      iconColor = colorScheme.primary;
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notification.id),
          );
        }
      },
      child: ListsCards.buildItemCard(
        context: context,
        item: notification,
        itemKey: ValueKey(notification.id),
        title: notification.title,
        value: 0,
        icon: notificationIcon,
        iconColor: iconColor,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color:
                    isRead
                        ? colorScheme.onSurface.withAlpha(153)
                        : colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(notification.timestamp),
              style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor:
            isRead ? colorScheme.surface : colorScheme.primary.withAlpha(13),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
