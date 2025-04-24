import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart'; // Use common AppBar
import 'package:finance_app/utils/common_widget/buttons.dart'; // Use common Buttons
import 'package:finance_app/utils/common_widget/input_fields.dart'; // Use common InputFields
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GroupNoteDetailScreen extends StatefulWidget {
  final GroupNoteModel note;

  const GroupNoteDetailScreen({super.key, required this.note});

  @override
  State<GroupNoteDetailScreen> createState() => _GroupNoteDetailScreenState();
}

class _GroupNoteDetailScreenState extends State<GroupNoteDetailScreen> {
  final TextEditingController commentController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  @override
  void dispose() {
    commentController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final noteState = context.watch<GroupNoteBloc>().state;

    final currentNote = noteState.notes.firstWhere(
          (n) => n.id == widget.note.id && n.groupId == widget.note.groupId,
      orElse: () => widget.note,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBarTabBar.buildAppBar( // Use common AppBar
        context: context,
        title: l10n.noteDetailTitle,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentNote.title,
                style: theme.textTheme.displayMedium, // Use theme style
              ),
              const SizedBox(height: 8),
              Text( // Keep Text, styled by theme
                '${l10n.createdBy}: ${currentNote.createdBy}',
                style: theme.textTheme.bodySmall,
              ),
              Text( // Keep Text, styled by theme
                Formatter.formatDateTime(
                  currentNote.createdAt,
                  locale: Localizations.localeOf(context),
                ),
                style: theme.textTheme.bodySmall,
              ),

              if (currentNote.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap( // Keep Wrap
                  spacing: 8,
                  runSpacing: 4,
                  children: currentNote.tags
                      .map(
                        (tag) => Chip( // Keep Chip, style based on theme
                      label: Text(tag, style: theme.textTheme.labelSmall),
                      backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5), // Use theme color
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                  )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Divider(color: theme.dividerColor.withValues(alpha: 0.5)), // Keep Divider
              const SizedBox(height: 16),
              Text( // Keep Text, styled by theme
                currentNote.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              Divider(color: theme.dividerColor.withValues(alpha: 0.5)), // Keep Divider
              const SizedBox(height: 16),
              UtilityWidgets.buildLabel( // Use common Label
                context: context,
                text: l10n.commentsLabel,
              ),
              const SizedBox(height: 8),
              _buildCommentsSection(context, currentNote),
              const SizedBox(height: 16),
              _buildAddCommentField(context, currentNote),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, GroupNoteModel note) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    final comments = note.comments..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: UtilityWidgets.buildEmptyState( // Use common EmptyState
          context: context,
          message: l10n.noComments,
          icon: Icons.comment_outlined,
        ),
      );
    }

    return ListView.separated( // Keep ListView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => Divider(
        color: theme.dividerColor.withValues(alpha: 0.3),
        height: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final comment = comments[index];
        // Keep ListTile, styled by theme
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          title: Text(
            comment.content,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${comment.userId.substring(0, 6)}... • ${DateFormat.yMd(locale.toString()).add_jm().format(comment.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddCommentField(BuildContext context, GroupNoteModel note) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row( // Keep Row
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: InputFields.buildTextField(
              controller: commentController,
              focusNode: commentFocusNode,
              label: "",
              hint: l10n.addCommentHint,
              maxLines: 3,
              isRequired: false,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Buttons.buildIconButton(
              context: context,
              icon: Icons.send,
              tooltip: l10n.sendButton,
              onPressed: _submitComment,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      UtilityWidgets.showCustomSnackBar(context: context, message: l10n.userNotLoggedInError);
      return;
    }

    final text = commentController.text.trim();
    if (text.isNotEmpty) {
      context.read<GroupNoteBloc>().add(
        AddComment(
          widget.note.id,
          CommentModel(
            userId: currentUser.uid,
            content: text,
            createdAt: DateTime.now(),
          ),
          groupId: widget.note.groupId,
        ),
      );
      commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }
}