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

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Key for the refresh indicator to programmatically trigger refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Refresh function that will be used by RefreshIndicator
  Future<void> _refreshNotifications(BuildContext context) async {
    // Reset notifications by re-initializing
    context.read<NotificationBloc>().add(InitializeNotifications());

    // Add a small delay to make the refresh experience smoother
    return Future.delayed(const Duration(milliseconds: 500));
  }

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
                return Row(
                  children: [
                    // Add refresh button
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: AppTheme.lightTheme.colorScheme.surface,
                      ),
                      tooltip: 'Refresh notifications',
                      onPressed: () {
                        _refreshIndicatorKey.currentState?.show();
                      },
                    ),
                    // Mark all as read button
                    IconButton(
                      icon: Icon(
                        Icons.done_all,
                        color: AppTheme.lightTheme.colorScheme.surface,
                      ),
                      tooltip: l10n.notificationsTooltipMarkAllRead,
                      onPressed:
                          () => context.read<NotificationBloc>().add(
                            MarkAllNotificationsAsRead(),
                          ),
                    ),
                  ],
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

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () => _refreshNotifications(context),
              child: CustomScrollView(
                slivers: [
                  // Savings Reminder Card
                  SliverToBoxAdapter(
                    child: Padding(
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
                  ),

                  // Notifications List Header
                  SliverToBoxAdapter(
                    child: Padding(
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
                  ),

                  // Notification List or Empty State
                  state.notifications.isEmpty
                      ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.notificationsEmptyMessage,
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  color: AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(153),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList.builder(
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
              ),
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
