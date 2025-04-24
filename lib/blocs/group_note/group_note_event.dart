part of 'group_note_bloc.dart';

abstract class GroupNoteEvent extends Equatable {
  const GroupNoteEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotes extends GroupNoteEvent {
  final String groupId;

  const LoadNotes(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

// Internal event to update state when stream emits data
class _UpdateNotes extends GroupNoteEvent {
  final List<GroupNoteModel> notes;

  const _UpdateNotes(this.notes);

  @override
  List<Object?> get props => [notes];
}

// Internal event to handle stream errors
class _NotesError extends GroupNoteEvent {
  final String message;
  const _NotesError(this.message);

  @override
  List<Object?> get props => [message];
}

class AddNote extends GroupNoteEvent {
  final GroupNoteModel note;

  const AddNote(this.note);

  @override
  List<Object?> get props => [note];
}

class EditNote extends GroupNoteEvent {
  final GroupNoteModel note;

  const EditNote(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteNote extends GroupNoteEvent {
  final String noteId;
  final String groupId;

  const DeleteNote(this.noteId, {required this.groupId});

  @override
  List<Object?> get props => [noteId, groupId];
}

class SearchNotes extends GroupNoteEvent {
  final String query;

  const SearchNotes(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterNotes extends GroupNoteEvent {
  final String? tag; // tag can be null (representing 'All')

  const FilterNotes(this.tag);

  @override
  List<Object?> get props => [tag];
}

class ToggleSearch extends GroupNoteEvent {
  final bool isSearching;

  const ToggleSearch(this.isSearching);

  @override
  List<Object?> get props => [isSearching];
}

class AddComment extends GroupNoteEvent {
  final String noteId;
  final CommentModel comment;
  final String groupId;

  const AddComment(this.noteId, this.comment, {required this.groupId});

  @override
  List<Object?> get props => [noteId, comment, groupId];
}