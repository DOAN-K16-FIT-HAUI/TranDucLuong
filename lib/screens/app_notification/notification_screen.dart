import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
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
            if (state.notifications.isEmpty) {
              return Center(
                child: Text(
                  l10n.notificationsEmptyMessage,
                  style: GoogleFonts.notoSans(
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
      child: ListsCards.buildItemCard(
        context: context,
        item: notification,
        itemKey: ValueKey(notification.id),
        title: notification.title,
        value: 0,
        icon: Icons.notifications,
        iconColor: colorScheme.primary,
        subtitle: Text(
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
        backgroundColor:
            isRead ? colorScheme.surface : colorScheme.primary.withAlpha(13),
      ),
    );
  }
}
