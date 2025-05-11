import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_event.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:finance_app/data/services/local_notification_service.dart';

class SavingsReminderScreen extends StatefulWidget {
  const SavingsReminderScreen({super.key});

  @override
  State<SavingsReminderScreen> createState() => _SavingsReminderScreenState();
}

class _SavingsReminderScreenState extends State<SavingsReminderScreen> {
  late TimeOfDay _selectedTime;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _messageController.text = 'Remember to set aside some savings today!';

    // Kiểm tra thông báo sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduledNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<NotificationBloc>().state;
    if (state.hasActiveReminder &&
        state.reminderHour != null &&
        state.reminderMinute != null) {
      _selectedTime = TimeOfDay(
        hour: state.reminderHour!,
        minute: state.reminderMinute!,
      );
      _messageController.text =
          state.reminderMessage ?? _messageController.text;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savingsReminderTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon and title
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE3F2FD),
                    child: Icon(
                      Icons.savings,
                      size: 40,
                      color: AppTheme.notificationInfoColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.savingsReminderDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Time picker
                ListTile(
                  title: Text(l10n.reminderTimeLabel),
                  subtitle: Text(
                    _formatTime(_selectedTime),
                    style: GoogleFonts.notoSans(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null && picked != _selectedTime) {
                      setState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Message field
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: l10n.reminderMessageLabel,
                    border: const OutlineInputBorder(),
                    hintText: l10n.reminderMessageHint,
                  ),
                  maxLines: 2,
                ),

                const Spacer(),

                // Active reminder indicator
                if (state.hasActiveReminder) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.notificationSuccessColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.notificationSuccessColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.notificationSuccessColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${l10n.activeReminderMessage} ${_formatTime(TimeOfDay(hour: state.reminderHour!, minute: state.reminderMinute!))}',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: AppTheme.notificationSuccessColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thêm nút kiểm tra thông báo
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.updateReminderButton ?? "Check reminders"),
                    onPressed: _checkScheduledNotifications,
                  ),
                  const SizedBox(height: 16),
                ],

                // Buttons
                Row(
                  children: [
                    if (state.hasActiveReminder) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: Text(l10n.cancelReminderButton),
                          onPressed: () {
                            context.read<NotificationBloc>().add(
                              CancelSavingsReminder(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.expenseColor,
                            foregroundColor: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.alarm_add),
                        label: Text(
                          state.hasActiveReminder
                              ? l10n.updateReminderButton
                              : l10n.setReminderButton,
                        ),
                        onPressed: () {
                          context.read<NotificationBloc>().add(
                            ScheduleSavingsReminder(
                              hour: _selectedTime.hour,
                              minute: _selectedTime.minute,
                              message: _messageController.text,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.reminderSetConfirmation),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void _checkScheduledNotifications() async {
    bool hasScheduled =
        await LocalNotificationService.checkPendingNotificationRequests();
    if (!mounted) return;

    if (!hasScheduled &&
        context.read<NotificationBloc>().state.hasActiveReminder) {
      // Thông báo đã được thiết lập trong state nhưng không có notification nào đang chờ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thông báo có thể không hoạt động. Vui lòng thử cài đặt lại.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
