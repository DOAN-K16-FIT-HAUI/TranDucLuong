import 'package:equatable/equatable.dart';
import 'package:finance_app/data/models/group_note.dart';

abstract class GroupNoteEvent extends Equatable {
  const GroupNoteEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupNotes extends GroupNoteEvent {}

class AddGroupNote extends GroupNoteEvent {
  final GroupNoteModel note;

  const AddGroupNote(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateGroupNote extends GroupNoteEvent {
  final GroupNoteModel note;

  const UpdateGroupNote(this.note);

  @override
  List<Object?> get props => [note];
}

class DeleteGroupNote extends GroupNoteEvent {
  final String noteId;

  const DeleteGroupNote(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class ToggleSearch extends GroupNoteEvent {
  final bool isSearching;

  const ToggleSearch(this.isSearching);

  @override
  List<Object?> get props => [isSearching];
}

class SearchGroupNotes extends GroupNoteEvent {
  final String query;

  const SearchGroupNotes(this.query);

  @override
  List<Object?> get props => [query];
}

class TabChanged extends GroupNoteEvent {
  final int tabIndex;

  const TabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class ReorderGroupNotes extends GroupNoteEvent {
  final String status;
  final int oldIndex;
  final int newIndex;

  const ReorderGroupNotes(this.status, this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [status, oldIndex, newIndex];
}

class LoadGroupNoteDetails extends GroupNoteEvent {
  final String noteId;

  const LoadGroupNoteDetails(this.noteId);

  @override
  List<Object?> get props => [noteId];
}