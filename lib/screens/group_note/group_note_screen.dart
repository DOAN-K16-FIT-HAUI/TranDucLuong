import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/blocs/group_note/group_note_event.dart';
import 'package:finance_app/blocs/group_note/group_note_state.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/screens/group_note/add_edit_group_note_screen.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GroupNoteScreen extends StatefulWidget {
  const GroupNoteScreen({super.key});

  @override
  State<GroupNoteScreen> createState() => _GroupNoteScreenState();
}

class _GroupNoteScreenState extends State<GroupNoteScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger LoadGroupNotes on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupNoteBloc>().add(LoadGroupNotes());
    });
  }

  List<GroupNoteModel> _getFilteredListForTab(GroupNoteState state, int tabIndex) {
    List<GroupNoteModel> listToFilter;
    switch (tabIndex) {
      case 0:
        listToFilter = state is GroupNoteLoaded ? state.allNotes : [];
        break;
      case 1:
        listToFilter = state is GroupNoteLoaded ? state.detailedNotes : [];
        break;
      case 2:
        listToFilter = state is GroupNoteLoaded ? state.summaryNotes : [];
        break;
      default:
        listToFilter = [];
    }

    if (state is! GroupNoteLoaded || state.searchQuery.isEmpty) {
      return listToFilter;
    }

    final lowerCaseQuery = state.searchQuery.toLowerCase();
    return listToFilter
        .where((note) => note.title.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final locale = localizationState.locale;

        return DefaultTabController(
          length: 3,
          initialIndex: 1, // Set default tab to "Ongoing" (index 1)
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: BlocConsumer<GroupNoteBloc, GroupNoteState>(
              listener: (context, state) {
                if (state is GroupNoteError) {
                  UtilityWidgets.showCustomSnackBar(
                    context: context,
                    message: state.message(context),
                    backgroundColor: theme.colorScheme.error,
                  );
                }
              },
              builder: (context, state) {
                final tabController = DefaultTabController.of(context);
                if (state is GroupNoteLoaded && tabController.index != state.selectedTab) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isWidgetMounted(context)) {
                      try {
                        if (tabController.index != state.selectedTab) {
                          tabController.animateTo(state.selectedTab);
                        }
                      } catch (e) {
                        debugPrint("Error animating TabController: $e");
                      }
                    }
                  });
                }

                final filteredAllNotes = _getFilteredListForTab(state, 0);
                final filteredDetailedNotes = _getFilteredListForTab(state, 1);
                final filteredSummaryNotes = _getFilteredListForTab(state, 2);

                return Column(
                  children: [
                    AppBarTabBar.buildAppBar(
                      context: context,
                      title: l10n.groupNoteTitle,
                      showBackButton: false,
                      backIcon: Icons.arrow_back,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      actions: [
                        IconButton(
                          icon: Icon(
                            state is GroupNoteLoaded && state.isSearching
                                ? Icons.close
                                : Icons.search,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          tooltip: state is GroupNoteLoaded && state.isSearching
                              ? l10n.closeSearchTooltip
                              : l10n.searchTooltip,
                          onPressed: () {
                            final bloc = context.read<GroupNoteBloc>();
                            bloc.add(ToggleSearch(state is GroupNoteLoaded && state.isSearching ? false : true));
                            if (state is GroupNoteLoaded && state.isSearching) {
                              bloc.add(SearchGroupNotes(''));
                            }
                          },
                        ),
                      ],
                    ),
                    if (state is GroupNoteLoading || state is GroupNoteInitial)
                      Expanded(
                        child: UtilityWidgets.buildLoadingIndicator(
                          context: context,
                        ),
                      ),
                    if (state is! GroupNoteLoading && state is! GroupNoteInitial) ...[
                      if (state is GroupNoteLoaded && state.isSearching)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: UtilityWidgets.buildSearchField(
                            context: context,
                            hintText: l10n.searchGroupNotesHint,
                            onChanged: (value) {
                              context.read<GroupNoteBloc>().add(
                                SearchGroupNotes(value),
                              );
                            },
                          ),
                        ),
                      AppBarTabBar.buildTabBar(
                        context: context,
                        tabTitles: [
                          l10n.statusEnded,
                          l10n.statusOngoing,
                          l10n.statusUpcoming,
                        ],
                        controller: tabController,
                        onTabChanged: (index) =>
                            context.read<GroupNoteBloc>().add(TabChanged(index)),
                      ),
                      Expanded(
                        child: state is GroupNoteError
                            ? UtilityWidgets.buildErrorState(
                          context: context,
                          message: state.message,
                          onRetry: () => context.read<GroupNoteBloc>().add(LoadGroupNotes()),
                        )
                            : TabBarView(
                          controller: tabController,
                          children: [
                            _buildTabContent(
                              context,
                              state,
                              filteredAllNotes,
                              'all',
                              locale,
                            ),
                            _buildTabContent(
                              context,
                              state,
                              filteredDetailedNotes,
                              'detailed',
                              locale,
                            ),
                            _buildTabContent(
                              context,
                              state,
                              filteredSummaryNotes,
                              'summary',
                              locale,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            floatingActionButton: Builder(
              builder: (fabContext) => FloatingActionButton(
                heroTag: "group_note_fab",
                onPressed: () {
                  final status = DefaultTabController.of(context).index == 0
                      ? 'all'
                      : DefaultTabController.of(context).index == 1
                      ? 'detailed'
                      : 'summary';
                  _showAddGroupNoteDialog(fabContext, status);
                },
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                tooltip: l10n.addNote,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    );
  }

  bool isWidgetMounted(BuildContext context) {
    try {
      context.widget;
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showAddGroupNoteDialog(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditGroupNoteScreen(
        status: status,
        onSave: (note) {
          context.read<GroupNoteBloc>().add(AddGroupNote(note));
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, GroupNoteModel note) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditGroupNoteScreen(
        note: note,
        status: note.status,
        onSave: (updatedNote) {
          context.read<GroupNoteBloc>().add(UpdateGroupNote(updatedNote));
        },
      ),
    );
  }

  Widget _buildGroupNoteCard(
      BuildContext context,
      GroupNoteModel note,
      String status,
      int index,
      Locale locale,
      ) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final menuItems = note.canEdit(currentUserId)
        ? MenuActions.buildEditDeleteMenuItems(
      context: context,
      editIcon: Icons.edit_outlined,
      deleteIcon: Icons.delete_outline,
    )
        : null;

    return ListsCards.buildItemCard(
      context: context,
      item: note,
      itemKey: Key('group_note_${note.id}'),
      title: note.title,
      subtitle: Text(
        '${DateFormat('dd/MM/yyyy').format(note.startDate)} - ${DateFormat('dd/MM/yyyy').format(note.endDate)}',
        style: theme.textTheme.bodySmall,
      ),
      value: note.amount,
      icon: Icons.note,
      iconColor: theme.colorScheme.onSurface,
      amountColor: note.amount >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
      valueLocale: locale.toString(),
      menuItems: menuItems,
      onMenuSelected: note.canEdit(currentUserId)
          ? (value) {
        MenuActions.handleEditDeleteActions(
          context: context,
          action: value,
          item: note,
          itemName: note.title,
          onEdit: (ctx, item) => _showEditDialog(ctx, item),
          onDelete: (ctx, item) => ctx.read<GroupNoteBloc>().add(DeleteGroupNote(item.id)),
        );
      }
          : null,
      onTap: () => AppRoutes.navigateToGroupNoteDetail(context, note),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTabContent(
      BuildContext context,
      GroupNoteState state,
      List<GroupNoteModel> items,
      String status,
      Locale locale,
      ) {
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message: state is GroupNoteLoaded && state.isSearching
            ? l10n.noMatchingTransactions
            : status == 'all'
            ? l10n.noAllNotes
            : status == 'detailed'
            ? l10n.noDetailedNotes
            : l10n.noSummaryNotes,
        suggestion: state is GroupNoteLoaded && state.isSearching ? null : l10n.addNoteSuggestion,
        icon: Icons.note_outlined,
        onActionPressed: state is GroupNoteLoaded && state.isSearching ? null : () => _showAddGroupNoteDialog(context, status),
        actionText: state is GroupNoteLoaded && state.isSearching ? null : l10n.addNote,
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (ctx, index) => _buildGroupNoteCard(ctx, items[index], status, index, locale),
      );
    }
  }
}