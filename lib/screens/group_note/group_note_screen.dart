import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/repositories/group_note_repository.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

class GroupNoteScreen extends StatefulWidget {
  const GroupNoteScreen({super.key});

  @override
  State<GroupNoteScreen> createState() => _GroupNoteScreenState();
}

class _GroupNoteScreenState extends State<GroupNoteScreen> {
  String? _selectedGroupId;
  List<Map<String, dynamic>> _userGroups = [];
  bool _isLoadingGroups = true;
  final GroupNoteRepository _groupNoteRepo = GetIt.instance<GroupNoteRepository>();

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGroups = true;
      _userGroups = [];
      _selectedGroupId = null;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingGroups = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('groupMemberships')
          .orderBy('joinedAt', descending: true)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) setState(() => _isLoadingGroups = false);
        return;
      }

      List<Map<String, dynamic>> groups = [];
      List<Future> groupDetailFutures = [];

      for (var doc in query.docs) {
        final data = doc.data();
        final groupId = data['groupId'] as String?;
        if (groupId != null) {
          groupDetailFutures.add(
              FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .get()
                  .then((groupDoc) {
                if (groupDoc.exists) {
                  final groupData = groupDoc.data()!;
                  groups.add({
                    'groupId': groupId,
                    'name': groupData['name'] ?? 'Unnamed Group',
                    'adminIds': List<String>.from(groupData['adminIds'] ?? []),
                  });
                } else {
                  debugPrint("Group document $groupId not found for user $userId's membership.");
                }
              })
                  .catchError((e) {
                debugPrint("Error fetching group details for $groupId: $e");
              })
          );
        }
      }

      await Future.wait(groupDetailFutures);

      // Sort groups alphabetically by name after fetching details
      groups.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));


      if (mounted) {
        setState(() {
          _userGroups = groups;
          _isLoadingGroups = false;
          if (groups.isNotEmpty) {
            _selectedGroupId = groups.first['groupId']; // Select the first group after sorting
            context.read<GroupNoteBloc>().add(LoadNotes(_selectedGroupId!));
          } else {
            context.read<GroupNoteBloc>().add(LoadNotes(''));
          }
        });
      }
    } catch (e) {
      print('Error in _loadUserGroups: $e');
      if (mounted) {
        setState(() => _isLoadingGroups = false);
        UtilityWidgets.showCustomSnackBar(
            context: context,
            message: '${AppLocalizations.of(context)!.errorLoadingGroups}: $e',
            backgroundColor: Theme.of(context).colorScheme.error,
            textStyle: TextStyle(color: Theme.of(context).colorScheme.onError));
        context.read<GroupNoteBloc>().add(LoadNotes(''));
      }
    }
  }


  Future<void> _createGroup(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final TextEditingController nameController = TextEditingController();
    final TextEditingController memberEmailController = TextEditingController();
    List<String> memberEmails = [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, stfSetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.colorScheme.surface,
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          title: Text(l10n.createGroup, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (fieldCtx) => InputFields.buildTextField(
                    controller: nameController,
                    label: l10n.groupNameLabel,
                    hint: l10n.groupNameHint,
                    isRequired: true,
                    validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.groupNameLabel, l10n: l10n),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (fieldCtx) => InputFields.buildTextField(
                    controller: memberEmailController,
                    label: l10n.addMemberEmailLabel,
                    hint: l10n.addMemberEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: false,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: theme.colorScheme.primary,
                      tooltip: l10n.addEmailTooltip,
                      onPressed: () {
                        final email = memberEmailController.text.trim().toLowerCase();
                        // SỬA LỖI VALIDATION: kiểm tra == null nghĩa là hợp lệ
                        if (email.isNotEmpty && Validators.validateEmail(email, l10n) == null) {
                          if (!memberEmails.contains(email)) {
                            stfSetState(() {
                              memberEmails.add(email);
                              memberEmailController.clear();
                            });
                          } else {
                            UtilityWidgets.showCustomSnackBar(
                                context: stfContext, message: l10n.emailAlreadyAdded);
                          }
                        } else if (email.isNotEmpty) {
                          // Hiển thị lỗi trả về từ validator nếu có, hoặc lỗi mặc định
                          final errorMsg = Validators.validateEmail(email, l10n) ?? l10n.invalidEmail;
                          UtilityWidgets.showCustomSnackBar(
                              context: stfContext, message: errorMsg);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (memberEmails.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: memberEmails
                        .map((email) => Chip(
                      label: Text(email, style: theme.textTheme.labelSmall),
                      onDeleted: () {
                        stfSetState(() { memberEmails.remove(email); });
                      },
                      deleteIconColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest, // Sửa thành surfaceContainerHighest cho chip nền tối
                    ))
                        .toList(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(l10n.addMembersInstruction, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              // SỬA LỖI withValues: dùng withOpacity
              child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  UtilityWidgets.showCustomSnackBar(context: dialogContext, message: l10n.groupNameRequired);
                  return;
                }
                // Sử dụng common loading dialog
                UtilityWidgets.showLoadingDialog(context, message: l10n.creatingGroup);

                try {
                  await _groupNoteRepo.createGroup(nameController.text.trim(), memberEmails);
                  if (!mounted) return;
                  Navigator.pop(context); // Pop loading
                  Navigator.pop(dialogContext);
                  await _loadUserGroups();
                  UtilityWidgets.showCustomSnackBar(context: context, message: l10n.groupCreatedSuccess);
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context); // Pop loading
                  UtilityWidgets.showCustomSnackBar(
                      context: dialogContext,
                      message: '${l10n.errorCreatingGroup}: $e',
                      backgroundColor: theme.colorScheme.error,
                      textStyle: TextStyle(color: theme.colorScheme.onError));
                }
              },
              child: Text(l10n.create, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final groupNoteBloc = context.watch<GroupNoteBloc>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBarTabBar.buildAppBar(
        context: context,
        title: l10n.groupNotesTitle,
        showBackButton: false,
        actions: [
          if (_userGroups.isNotEmpty && _selectedGroupId != null) ...[
            IconButton(
              icon: Icon( groupNoteBloc.state.isSearching ? Icons.close : Icons.search,),
              tooltip: groupNoteBloc.state.isSearching ? l10n.closeSearchTooltip : l10n.searchTooltip,
              onPressed: () => groupNoteBloc.add(ToggleSearch(!groupNoteBloc.state.isSearching)),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: l10n.filterTooltip,
              onPressed: () => _showFilterDialog(context),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: l10n.createGroup,
            onPressed: () => _createGroup(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingGroups)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: UtilityWidgets.buildLoadingIndicator(context: context),
            )
          else if (_userGroups.isEmpty)
            Expanded(
              child: UtilityWidgets.buildEmptyState(
                context: context,
                message: l10n.noGroupsFound,
                icon: Icons.group_off_outlined,
                suggestion: l10n.joinGroupSuggestion,
                actionText: l10n.createGroup,
                onActionPressed: () => _createGroup(context),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: InputFields.buildDropdownField<String>(
                label: l10n.selectGroup,
                value: _selectedGroupId,
                isRequired: false,
                items: _userGroups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group['groupId'],
                    child: Text(
                      group['name'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null && value != _selectedGroupId) {
                    setState(() { _selectedGroupId = value; });
                    groupNoteBloc.add(const ToggleSearch(false));
                    groupNoteBloc.add(const FilterNotes(null));
                    groupNoteBloc.add(LoadNotes(value));
                  }
                },
              ),
            ),

          Expanded(
            child: _selectedGroupId == null
                ? Center(child: Text(l10n.pleaseSelectGroup))
                : BlocBuilder<GroupNoteBloc, GroupNoteState>(
              builder: (context, state) {
                if (state.isLoading && state.notes.isEmpty) {
                  return UtilityWidgets.buildLoadingIndicator(context: context);
                }
                if (state.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: UtilityWidgets.buildErrorState(
                        context: context,
                        message: (ctx) => state.error!(ctx),
                        onRetry: () => groupNoteBloc.add(LoadNotes(_selectedGroupId!)),
                      ),
                    ),
                  );
                }

                final notesToShow = state.filteredNotes;

                return Column(
                  children: [
                    if (state.isSearching)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: UtilityWidgets.buildSearchField(
                          context: context,
                          hintText: l10n.searchGroupNotesHint,
                          onChanged: (value) => groupNoteBloc.add(SearchNotes(value)),
                        ),
                      ),
                    Expanded(
                      child: notesToShow.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: UtilityWidgets.buildEmptyState(
                          context: context,
                          message: state.isSearching || state.selectedTag != null
                              ? l10n.noNotesFoundSearchFilter
                              : l10n.noNotesInGroup,
                          suggestion: state.isSearching || state.selectedTag != null
                              ? l10n.tryDifferentSearchFilter
                              : l10n.addNoteSuggestion,
                          icon: Icons.notes_outlined,
                          actionText: state.isSearching || state.selectedTag != null
                              ? null
                              : l10n.addNote,
                          onActionPressed: state.isSearching || state.selectedTag != null
                              ? null
                              : () => _navigateToAddEditNote(context, null),
                        ),
                      )
                      // SỬA LỖI buildList: dùng ListView.builder trực tiếp
                          : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // Thêm padding cần thiết
                        itemCount: notesToShow.length,
                        itemBuilder: (ctx, index) => _buildNoteCard(ctx, notesToShow[index], index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedGroupId == null || _isLoadingGroups
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditNote(context, null),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.addNote),
        tooltip: l10n.addNoteTooltip,
      ),
    );
  }

  void _navigateToAddEditNote(BuildContext context, GroupNoteModel? note) {
    AppRoutes.navigateToAddEditGroupNote(
      context,
      note,
      note == null ? 'add' : 'edit',
          (savedNote) {
        final bloc = context.read<GroupNoteBloc>();
        if (note == null) { bloc.add(AddNote(savedNote)); }
        else { bloc.add(EditNote(savedNote)); }
      },
      groupId: _selectedGroupId!,
    );
  }


  Widget _buildNoteCard(BuildContext context, GroupNoteModel note, int index) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    IconData cardIcon = Icons.notes_outlined;
    if (note.tags.contains(l10n.tagExpense)) cardIcon = Icons.receipt_long_outlined;
    else if (note.tags.contains(l10n.tagGoal)) cardIcon = Icons.flag_outlined;

    return ListsCards.buildItemCard(
      context: context,
      item: note,
      itemKey: ValueKey(note.id),
      title: note.title,
      subtitle: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        // SỬA LỖI withValues: Dùng style mặc định hoặc theme.textTheme
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
      ),
      icon: cardIcon,
      iconColor: theme.colorScheme.secondary,
      menuItems: MenuActions.buildEditDeleteMenuItems(context: context),
      onMenuSelected: (result) {
        MenuActions.handleEditDeleteActions<GroupNoteModel>(
          context: context,
          action: result,
          item: note,
          itemName: note.title,
          onEdit: (ctx, item) => _navigateToAddEditNote(ctx, item),
          onDelete: (ctx, item) => ctx.read<GroupNoteBloc>().add(
            DeleteNote(item.id, groupId: _selectedGroupId!),
          ),
        );
      },
      onTap: () => AppRoutes.navigateToGroupNoteDetail(context, note),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bloc = context.read<GroupNoteBloc>();
    final currentFilter = bloc.state.selectedTag;

    final List<String?> filterTags = [ null, l10n.tagExpense, l10n.tagNote, l10n.tagGoal, l10n.tagOther ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Text(l10n.filterNotesTitle, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
        // SỬA LỖI GỌI HÀM buildCategoryChips (đảm bảo hàm đã được sửa ở file utils)
        content: UtilityWidgets.buildCategoryChips<String?>(
          context: context,
          categories: filterTags,
          selectedCategory: currentFilter,
          categoryLabelBuilder: (tag) => tag ?? l10n.all, // Đảm bảo tham số này tồn tại và được dùng
          onCategorySelected: (tag) {
            bloc.add(FilterNotes(tag));
            Navigator.pop(dialogContext);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            // SỬA LỖI withValues: dùng withOpacity
            child: Text(l10n.cancel, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}