import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/blocs/group_note/group_note_event.dart';
import 'package:finance_app/blocs/group_note/group_note_state.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/screens/group_note/add_edit_group_note_screen.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GroupNoteDetailScreen extends StatelessWidget {
  final GroupNoteModel note;

  const GroupNoteDetailScreen({super.key, required this.note});

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditGroupNoteScreen(
        note: note,
        status: note.status,
        onSave: (updatedNote) {
          context.read<GroupNoteBloc>().add(UpdateGroupNote(updatedNote));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Trigger loading of group note details
    context.read<GroupNoteBloc>().add(LoadGroupNoteDetails(note.id));

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final locale = localizationState.locale;

        return BlocBuilder<GroupNoteBloc, GroupNoteState>(
          builder: (context, state) {
            // Default balance values
            double totalAmountPaid = 0;
            double totalIncome = 0;
            double totalExpense = 0;
            double remainingAmount = note.amount;
            Map<String, double> participantBalances = {
              for (var p in note.participants) p: 0.0
            };

            // Update balances if state provides details
            if (state is GroupNoteDetailsLoaded && state.noteId == note.id) {
              totalAmountPaid = state.totalAmountPaid;
              totalIncome = state.totalIncome;
              totalExpense = state.totalExpense;
              remainingAmount = state.remainingAmount;
              participantBalances = state.participantBalances;
            }

            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBarTabBar.buildAppBar(
                context: context,
                title: note.title,
                showBackButton: true,
                backIcon: Icons.arrow_back,
                backgroundColor: theme.appBarTheme.backgroundColor,
                foregroundColor: theme.appBarTheme.foregroundColor,
                onBackPressed: () => GoRouter.of(context).pop(),
                actions: note.canEdit(currentUserId)
                    ? [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: theme.appBarTheme.foregroundColor,
                    ),
                    onPressed: () => _showEditDialog(context),
                  ),
                ]
                    : [],
              ),
              body: state is GroupNoteLoading
                  ? UtilityWidgets.buildLoadingIndicator(context: context)
                  : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UtilityWidgets.buildLabel(
                                context: context,
                                text: l10n.startDateLabel,
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(note.startDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UtilityWidgets.buildLabel(
                                context: context,
                                text: l10n.endDateLabel,
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(note.endDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListsCards.buildItemCard(
                        context: context,
                        item: note,
                        itemKey: Key('total_amount_paid_${note.id}'),
                        title: l10n.totalAmountPaidLabel,
                        value: totalAmountPaid,
                        icon: Icons.money,
                        iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        amountColor: theme.colorScheme.onSurface,
                        valueLocale: locale.toString(),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      ListsCards.buildItemCard(
                        context: context,
                        item: note,
                        itemKey: Key('total_income_${note.id}'),
                        title: l10n.totalIncomeLabel,
                        value: totalIncome,
                        icon: Icons.account_balance_wallet,
                        iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        amountColor: theme.colorScheme.onSurface,
                        valueLocale: locale.toString(),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      ListsCards.buildItemCard(
                        context: context,
                        item: note,
                        itemKey: Key('total_expense_${note.id}'),
                        title: l10n.totalExpenseLabel,
                        value: totalExpense,
                        icon: Icons.money_off,
                        iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        amountColor: theme.colorScheme.onSurface,
                        valueLocale: locale.toString(),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      ListsCards.buildItemCard(
                        context: context,
                        item: note,
                        itemKey: Key('remaining_amount_${note.id}'),
                        title: l10n.remainingAmountLabel,
                        value: remainingAmount,
                        icon: Icons.savings,
                        iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        amountColor: theme.colorScheme.onSurface,
                        valueLocale: locale.toString(),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(height: 16),
                      UtilityWidgets.buildLabel(
                        context: context,
                        text: l10n.participantsListLabel,
                      ),
                      const SizedBox(height: 8),
                      if (note.participants.isEmpty)
                        UtilityWidgets.buildEmptyState(
                          context: context,
                          message: l10n.noItemsFound,
                          icon: Icons.group_outlined,
                        )
                      else
                        ...note.participants.map(
                              (participant) => ListsCards.buildItemCard(
                            context: context,
                            item: participant,
                            itemKey: Key('participant_$participant'),
                            title: participant,
                            icon: Icons.person,
                            iconColor: theme.colorScheme.primary,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            value: participantBalances[participant] ?? 0.0,
                            valueLocale: locale.toString(),
                            amountColor: (participantBalances[participant] ?? 0.0) >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Buttons.buildSubmitButton(
                        context,
                        l10n.splitMoneyButton,
                            () {},
                        backgroundColor: theme.colorScheme.surface,
                        textColor: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Buttons.buildSubmitButton(
                        context,
                        l10n.noteButton,
                            () {},
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}