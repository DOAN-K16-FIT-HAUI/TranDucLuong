import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class AddEditGroupNoteScreen extends StatefulWidget {
  final GroupNoteModel? note;
  final String status;
  final Function(GroupNoteModel) onSave;

  const AddEditGroupNoteScreen({
    super.key,
    this.note,
    required this.status,
    required this.onSave,
  });

  @override
  State<AddEditGroupNoteScreen> createState() => _AddEditGroupNoteScreenState();
}

class _AddEditGroupNoteScreenState extends State<AddEditGroupNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _participantController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _status;
  late List<String> _participants;
  late final GlobalKey<FormState> _formKey;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _amountController = TextEditingController(
      text: widget.note?.amount.toString() ?? '',
    );
    _noteController = TextEditingController(text: widget.note?.note ?? '');
    _participantController = TextEditingController();
    _startDate = widget.note?.startDate ?? DateTime.now();
    _endDate = widget.note?.endDate ?? DateTime.now();
    _status = widget.note?.status ?? widget.status;
    _participants = widget.note?.participants ?? [];
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final participant = _participantController.text.trim();
    if (participant.isNotEmpty && !_participants.contains(participant)) {
      setState(() {
        _participants.add(participant);
        _participantController.clear();
      });
    }
  }

  void _removeParticipant(String participant) {
    setState(() {
      _participants.remove(participant);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        widget.note == null ? l10n.addNote : l10n.edit,
        style: GoogleFonts.poppins(
          textStyle: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputFields.buildTextField(
                  controller: _titleController,
                  label: l10n.titleLabel,
                  hint: l10n.enterTitleHint,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterTitleHint;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputFields.buildDatePickerField(
                  context: context,
                  label: l10n.startDateLabel,
                  date: _startDate,
                  onTap: (picked) {
                    setState(() {
                      _startDate = picked;
                    });
                  },
                  errorText: _startDate == null ? l10n.selectDateError : null,
                ),
                InputFields.buildDatePickerField(
                  context: context,
                  label: l10n.endDateLabel,
                  date: _endDate,
                  onTap: (picked) {
                    setState(() {
                      _endDate = picked;
                    });
                  },
                  errorText: _endDate == null ? l10n.selectDateError : null,
                ),
                const SizedBox(height: 16),
                InputFields.buildBalanceInputField(
                  _amountController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterAmountHint;
                    }
                    final amount = double.tryParse(value.replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      return l10n.invalidAmountError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                UtilityWidgets.buildLabel(
                  context: context,
                  text: l10n.participantsLabel,
                ),
                Row(
                  children: [
                    Expanded(
                      child: InputFields.buildTextField(
                        controller: _participantController,
                        label: l10n.addParticipantLabel,
                        hint: l10n.enterParticipantHint,
                        isRequired: false,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: theme.colorScheme.primary),
                      onPressed: _addParticipant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._participants.map(
                      (participant) => ListsCards.buildItemCard(
                    context: context,
                    item: participant,
                    itemKey: Key('participant_$participant'),
                    title: participant,
                    icon: Icons.person,
                    iconColor: theme.colorScheme.primary,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    onTap: () {
                      _removeParticipant(participant);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                UtilityWidgets.buildLabel(
                  context: context,
                  text: l10n.statusLabel,
                ),
                RadioListTile<String>(
                  title: Text(
                    l10n.statusEnded,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: 'all',
                  groupValue: _status,
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    l10n.statusOngoing,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: 'detailed',
                  groupValue: _status,
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    l10n.statusUpcoming,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: 'summary',
                  groupValue: _status,
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                InputFields.buildTextField(
                  controller: _noteController,
                  label: l10n.noteLabel,
                  hint: l10n.enterNoteHint,
                  maxLines: 3,
                  isRequired: false,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Buttons.buildSubmitButton(
                context,
                l10n.cancelButton,
                    () => Navigator.of(context).pop(),
                backgroundColor: theme.colorScheme.surface,
                textColor: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Buttons.buildSubmitButton(
                context,
                widget.note == null ? l10n.add : l10n.saveButton,
                    () {
                  if (_formKey.currentState!.validate() &&
                      _startDate != null &&
                      _endDate != null) {
                    final currentUserId = _auth.currentUser?.uid ?? '';
                    final note = GroupNoteModel(
                      id: widget.note?.id ?? const Uuid().v4(),
                      title: _titleController.text,
                      startDate: _startDate!,
                      endDate: _endDate!,
                      amount: double.parse(
                        _amountController.text.replaceAll(',', ''),
                      ),
                      status: _status,
                      note: _noteController.text,
                      participants: _participants,
                      creatorId: widget.note?.creatorId ?? currentUserId,
                    );
                    widget.onSave(note);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}