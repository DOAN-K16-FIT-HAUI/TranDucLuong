import 'dart:async'; // Import async
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/repositories/group_note_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import l10n

part 'group_note_event.dart';
part 'group_note_state.dart';

class GroupNoteBloc extends Bloc<GroupNoteEvent, GroupNoteState> {
  final GroupNoteRepository groupNoteRepository;
  StreamSubscription? _notesSubscription; // Keep track of the subscription

  GroupNoteBloc({required this.groupNoteRepository})
      : super(const GroupNoteState()) {
    on<LoadNotes>(_onLoadNotes);
    on<_UpdateNotes>(_onUpdateNotes); // Handle internal update event
    on<_NotesError>(_onNotesError);   // Handle internal error event
    on<AddNote>(_onAddNote);
    on<EditNote>(_onEditNote);
    on<DeleteNote>(_onDeleteNote);
    on<SearchNotes>(_onSearchNotes);
    on<FilterNotes>(_onFilterNotes);
    on<ToggleSearch>(_onToggleSearch);
    on<AddComment>(_onAddComment);
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel(); // Cancel subscription when Bloc is closed
    return super.close();
  }

  Future<void> _onLoadNotes(
      LoadNotes event, Emitter<GroupNoteState> emit) async {
    emit(state.copyWith(isLoading: true, error: null, clearError: true)); // Clear previous error
    await _notesSubscription?.cancel(); // Cancel previous subscription if any

    try {
      _notesSubscription =
          groupNoteRepository.getGroupNotes(event.groupId).listen(
                (notes) {
              add(_UpdateNotes(notes)); // Trigger internal update event
            },
            onError: (error) {
              add(_NotesError("Error loading notes: ${error.toString()}")); // Trigger internal error event
            },
          );
      // Don't set isLoading to false here, let _UpdateNotes or _NotesError handle it
    } catch (e) {
      // Catch synchronous errors during stream setup
      emit(state.copyWith(
        isLoading: false,
        error: (context) => AppLocalizations.of(context)!.errorLoadingData + " (Setup)",
      ));
    }
  }

  // Handles updates from the Firestore stream
  void _onUpdateNotes(_UpdateNotes event, Emitter<GroupNoteState> emit) {
    final filtered = _applyFiltersAndSearch(event.notes, state.searchQuery, state.selectedTag);
    emit(state.copyWith(
      isLoading: false, // Loading finished
      notes: event.notes,
      filteredNotes: filtered,
      error: null, // Clear error on successful update
      clearError: true,
    ));
  }

  // Handles errors from the Firestore stream
  void _onNotesError(_NotesError event, Emitter<GroupNoteState> emit) {
    emit(state.copyWith(
      isLoading: false,
      error: (context) => event.message, // Show the error message
    ));
  }


  Future<void> _onAddNote(AddNote event, Emitter<GroupNoteState> emit) async {
    try {
      // Optimistic UI update (optional): add note locally first
      // emit(state.copyWith(notes: [...state.notes, event.note]));
      await groupNoteRepository.addGroupNote(event.note);
      // No explicit emit needed here if listening to the stream
    } catch (e) {
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.errorAddingNote,
        // Optionally revert optimistic update if it failed
      ));
    }
  }

  Future<void> _onEditNote(EditNote event, Emitter<GroupNoteState> emit) async {
    try {
      // Optimistic UI update (optional)
      await groupNoteRepository.updateGroupNote(event.note);
      // Stream will handle the update
    } catch (e) {
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.errorUpdatingNote,
      ));
    }
  }

  Future<void> _onDeleteNote(
      DeleteNote event, Emitter<GroupNoteState> emit) async {
    // Optimistic UI update: Remove immediately
    final optimisticNotes = state.notes.where((note) => note.id != event.noteId).toList();
    final optimisticFiltered = state.filteredNotes.where((note) => note.id != event.noteId).toList();
    emit(state.copyWith(notes: optimisticNotes, filteredNotes: optimisticFiltered));

    try {
      await groupNoteRepository.deleteGroupNote(event.noteId, event.groupId);
      // Stream listener will eventually confirm, but UI is already updated
    } catch (e) {
      // Revert optimistic update if delete failed
      add(LoadNotes(event.groupId)); // Reload to get the correct state
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.errorDeletingNote,
      ));
    }
  }

  void _onSearchNotes(SearchNotes event, Emitter<GroupNoteState> emit) {
    final filtered =
    _applyFiltersAndSearch(state.notes, event.query, state.selectedTag);
    emit(state.copyWith(
      filteredNotes: filtered,
      searchQuery: event.query,
    ));
  }

  void _onFilterNotes(FilterNotes event, Emitter<GroupNoteState> emit) {
    final filtered =
    _applyFiltersAndSearch(state.notes, state.searchQuery, event.tag);
    emit(state.copyWith(
      filteredNotes: filtered,
      selectedTag: event.tag, // Directly use event.tag (can be null)
    ));
  }

  void _onToggleSearch(ToggleSearch event, Emitter<GroupNoteState> emit) {
    // When toggling search off, reset search query and re-apply filters
    String query = event.isSearching ? state.searchQuery : '';
    final notesToFilter = state.notes;
    final filtered = _applyFiltersAndSearch(notesToFilter, query, state.selectedTag);

    emit(state.copyWith(
      isSearching: event.isSearching,
      searchQuery: query, // Reset query if turning search off
      filteredNotes: filtered,
    ));
  }

  Future<void> _onAddComment(
      AddComment event, Emitter<GroupNoteState> emit) async {
    try {
      // Optimistic UI update (optional): Add comment locally
      await groupNoteRepository.addComment(
          event.noteId, event.comment, event.groupId);
      // Stream listener will update the note with the new comment
    } catch (e) {
      emit(state.copyWith(
        error: (context) => AppLocalizations.of(context)!.errorAddingComment,
      ));
    }
  }

  List<GroupNoteModel> _applyFiltersAndSearch(
      List<GroupNoteModel> notes, String query, String? tag) {
    var filtered = notes;

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Filter by tag if a tag is selected (tag is not null and not empty)
    if (tag != null && tag.isNotEmpty) {
      filtered = filtered.where((note) => note.tags.contains(tag)).toList();
    }

    return filtered;
  }
}