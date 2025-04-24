part of 'group_note_bloc.dart';

class GroupNoteState extends Equatable {
  final List<GroupNoteModel> notes;
  final List<GroupNoteModel> filteredNotes;
  final bool isLoading;
  final bool isSearching;
  final String searchQuery;
  final String? selectedTag;
  final String Function(BuildContext)?
  error; // Function to get localized error message

  const GroupNoteState({
    this.notes = const [],
    this.filteredNotes = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.selectedTag, // Null represents 'All' filter
    this.error,
  });

  GroupNoteState copyWith({
    List<GroupNoteModel>? notes,
    List<GroupNoteModel>? filteredNotes,
    bool? isLoading,
    bool? isSearching,
    String? searchQuery,
    // Use Object() to allow setting tag to null explicitly
    Object? selectedTag = const Object(),
    String Function(BuildContext)? error,
    bool clearError = false, // Flag to explicitly clear error
  }) {
    return GroupNoteState(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag is String? ? selectedTag : this.selectedTag,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    notes,
    filteredNotes,
    isLoading,
    isSearching,
    searchQuery,
    selectedTag,
    error,
  ];
}