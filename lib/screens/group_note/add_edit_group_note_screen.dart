import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart'; // Use common app bar
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddEditGroupNoteScreen extends StatefulWidget {
  final GroupNoteModel? note;
  final String status;
  final String groupId;
  final Function(GroupNoteModel) onSave;

  const AddEditGroupNoteScreen({
    super.key,
    this.note,
    required this.status,
    required this.groupId,
    required this.onSave,
  });

  @override
  State<AddEditGroupNoteScreen> createState() => _AddEditGroupNoteScreenState();
}

class _AddEditGroupNoteScreenState extends State<AddEditGroupNoteScreen> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  late final GlobalKey<FormState> formKey;
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    contentController = TextEditingController(text: widget.note?.content ?? '');
    formKey = GlobalKey<FormState>();
    selectedTag = (widget.note?.tags != null && widget.note!.tags.isNotEmpty)
        ? widget.note!.tags[0]
        : null;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEdit = widget.status == 'edit';

    final List<String> availableTags = [
      l10n.tagExpense,
      l10n.tagNote,
      l10n.tagGoal,
      l10n.tagOther,
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      appBar: AppBarTabBar.buildAppBar( // Use common AppBar
        context: context,
        title: isEdit ? l10n.editNoteDialogTitle : l10n.addNoteDialogTitle,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputFields.buildTextField( // Use common TextField
                controller: titleController,
                label: l10n.noteTitleLabel,
                hint: l10n.noteTitleHint,
                validator: (value) => Validators.validateNotEmpty(
                    value,
                    fieldName: l10n.noteTitleLabel,
                    l10n: l10n // Pass l10n for validation messages
                ),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              InputFields.buildTextField( // Use common TextField
                controller: contentController,
                label: l10n.noteContentLabel,
                hint: l10n.noteContentHint,
                maxLines: 5,
                validator: (value) => Validators.validateNotEmpty(
                    value,
                    fieldName: l10n.noteContentLabel,
                    l10n: l10n),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              InputFields.buildDropdownField<String>( // Use common Dropdown
                label: l10n.noteTagLabel,
                value: selectedTag,
                items: availableTags
                    .map((tag) => DropdownMenuItem(
                  value: tag,
                  child: Text(tag, style: theme.textTheme.bodyMedium),
                ))
                    .toList(),
                onChanged: (value) => setState(() => selectedTag = value),
                hint: l10n.selectTagHint,
                isRequired: false,
                // validator: (value) => Validators.validateCategory(value, l10n: l10n) // Example validator if needed
              ),
              const SizedBox(height: 24),
              Buttons.buildSubmitButton( // Use common Button
                context,
                isEdit ? l10n.saveButton : l10n.addNote,
                    () {
                  if (formKey.currentState!.validate()) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      UtilityWidgets.showCustomSnackBar(context: context, message: l10n.userNotLoggedInError);
                      return;
                    }

                    final note = GroupNoteModel(
                      id: widget.note?.id ?? '',
                      groupId: widget.groupId,
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      createdBy: widget.note?.createdBy ?? currentUser.uid,
                      createdAt: widget.note?.createdAt ?? DateTime.now(),
                      tags: selectedTag != null ? [selectedTag!] : [],
                      comments: widget.note?.comments ?? [],
                    );
                    widget.onSave(note);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}