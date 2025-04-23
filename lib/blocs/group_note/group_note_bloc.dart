import 'package:finance_app/blocs/group_note/group_note_event.dart';
import 'package:finance_app/blocs/group_note/group_note_state.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/repositories/group_note_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GroupNoteBloc extends Bloc<GroupNoteEvent, GroupNoteState> {
  final GroupNoteRepository groupNoteRepository;

  GroupNoteBloc({required this.groupNoteRepository})
      : super(GroupNoteInitial()) {
    on<LoadGroupNotes>(_onLoadGroupNotes);
    on<AddGroupNote>(_onAddGroupNote);
    on<UpdateGroupNote>(_onUpdateGroupNote);
    on<DeleteGroupNote>(_onDeleteGroupNote);
    on<ToggleSearch>(_onToggleSearch);
    on<SearchGroupNotes>(_onSearchGroupNotes);
    on<TabChanged>(_onTabChanged);
    on<ReorderGroupNotes>(_onReorderGroupNotes);
    on<LoadGroupNoteDetails>(_onLoadGroupNoteDetails);
  }

  Future<void> _onLoadGroupNotes(
      LoadGroupNotes event, Emitter<GroupNoteState> emit) async {
    emit(GroupNoteLoading(
        isSearching: state is GroupNoteLoaded ? (state as GroupNoteLoaded).isSearching : false));
    try {
      final notes = await groupNoteRepository.getGroupNotes();
      final allNotes = notes.where((note) => note.status == 'all').toList();
      final detailedNotes = notes.where((note) => note.status == 'detailed').toList();
      final summaryNotes = notes.where((note) => note.status == 'summary').toList();

      if (allNotes.isEmpty && detailedNotes.isEmpty && summaryNotes.isEmpty) {
        emit(GroupNoteError(
                (context) => AppLocalizations.of(context)!.noAllNotes));
        return;
      }

      emit(GroupNoteLoaded(
        allNotes: allNotes,
        detailedNotes: detailedNotes,
        summaryNotes: summaryNotes,
        searchQuery: state is GroupNoteLoaded
            ? (state as GroupNoteLoaded).searchQuery
            : '',
        isSearching: state is GroupNoteLoaded
            ? (state as GroupNoteLoaded).isSearching
            : false,
        selectedTab: state is GroupNoteLoaded
            ? (state as GroupNoteLoaded).selectedTab
            : 1, // Default to "Ongoing" tab
      ));
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }

  Future<void> _onAddGroupNote(
      AddGroupNote event, Emitter<GroupNoteState> emit) async {
    try {
      await groupNoteRepository.addGroupNote(event.note);
      add(LoadGroupNotes());
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }

  Future<void> _onUpdateGroupNote(
      UpdateGroupNote event, Emitter<GroupNoteState> emit) async {
    try {
      await groupNoteRepository.updateGroupNote(event.note);
      add(LoadGroupNotes());
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }

  Future<void> _onDeleteGroupNote(
      DeleteGroupNote event, Emitter<GroupNoteState> emit) async {
    try {
      await groupNoteRepository.deleteGroupNote(event.noteId);
      add(LoadGroupNotes());
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }

  Future<void> _onToggleSearch(
      ToggleSearch event, Emitter<GroupNoteState> emit) async {
    if (state is GroupNoteLoaded) {
      final currentState = state as GroupNoteLoaded;
      emit(GroupNoteLoaded(
        allNotes: currentState.allNotes,
        detailedNotes: currentState.detailedNotes,
        summaryNotes: currentState.summaryNotes,
        searchQuery: currentState.searchQuery,
        isSearching: event.isSearching,
        selectedTab: currentState.selectedTab,
      ));
    }
  }

  Future<void> _onSearchGroupNotes(
      SearchGroupNotes event, Emitter<GroupNoteState> emit) async {
    if (state is GroupNoteLoaded) {
      final currentState = state as GroupNoteLoaded;
      emit(GroupNoteLoaded(
        allNotes: currentState.allNotes,
        detailedNotes: currentState.detailedNotes,
        summaryNotes: currentState.summaryNotes,
        searchQuery: event.query,
        isSearching: currentState.isSearching,
        selectedTab: currentState.selectedTab,
      ));
    }
  }

  Future<void> _onTabChanged(TabChanged event, Emitter<GroupNoteState> emit) async {
    if (state is GroupNoteLoaded) {
      final currentState = state as GroupNoteLoaded;
      emit(GroupNoteLoaded(
        allNotes: currentState.allNotes,
        detailedNotes: currentState.detailedNotes,
        summaryNotes: currentState.summaryNotes,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        selectedTab: event.tabIndex,
      ));
    }
  }

  Future<void> _onReorderGroupNotes(
      ReorderGroupNotes event, Emitter<GroupNoteState> emit) async {
    try {
      final currentState = state as GroupNoteLoaded;
      List<GroupNoteModel> notes;
      if (event.status == 'all') {
        notes = List<GroupNoteModel>.from(currentState.allNotes);
      } else if (event.status == 'detailed') {
        notes = List<GroupNoteModel>.from(currentState.detailedNotes);
      } else {
        notes = List<GroupNoteModel>.from(currentState.summaryNotes);
      }

      final note = notes[event.oldIndex];
      notes.removeAt(event.oldIndex);
      notes.insert(event.newIndex, note);

      await groupNoteRepository.updateGroupNoteOrder(notes);
      add(LoadGroupNotes());
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }

  Future<void> _onLoadGroupNoteDetails(
      LoadGroupNoteDetails event, Emitter<GroupNoteState> emit) async {
    emit(GroupNoteLoading());
    try {
      // Fetch group note to get amount and participants
      final notes = await groupNoteRepository.getGroupNotes();
      final note = notes.firstWhere((n) => n.id == event.noteId, orElse: () => throw Exception('Note not found'));

      // Placeholder: Assume no transaction data, split amount equally
      final participantCount = note.participants.isNotEmpty ? note.participants.length : 1;
      final splitAmount = note.amount / participantCount;
      final participantBalances = {
        for (var participant in note.participants) participant: splitAmount
      };

      emit(GroupNoteDetailsLoaded(
        noteId: event.noteId,
        totalAmountPaid: note.amount, // Placeholder: Assume amount is paid
        totalIncome: 0, // No transaction data
        totalExpense: 0, // No transaction data
        remainingAmount: note.amount, // Placeholder: No expenses yet
        participantBalances: participantBalances,
      ));
    } catch (e) {
      emit(GroupNoteError(
              (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString())));
    }
  }
}