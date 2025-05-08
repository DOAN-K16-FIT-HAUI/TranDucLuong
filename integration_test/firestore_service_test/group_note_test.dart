import 'package:finance_app/blocs/group_note/group_note_bloc.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/repositories/group_note_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../test_helpers.dart';

class MockGroupNoteBloc extends Mock implements GroupNoteBloc {}

void main() {
  late FirebaseAuthService authService;
  late GroupNoteRepository groupNoteRepository;
  late GroupNoteBloc groupNoteBloc;
  late FirestoreService firestoreService;
  late String testEmail;
  late String testGroupId;
  const testPassword = 'testpassword';
  const testGroupName = 'Test Group';

  setUpAll(() async {
    // Initialize Firebase with emulators
    await initFirebase();

    // Initialize services
    authService = FirebaseAuthService();
    firestoreService = FirestoreService();
    groupNoteRepository = GroupNoteRepository(firestoreService);
    groupNoteBloc = GroupNoteBloc(groupNoteRepository: groupNoteRepository);
  });

  setUp(() async {
    // Create a new test email for each test
    testEmail = await generateTestEmail();

    // Ensure user is logged out
    await FirebaseAuth.instance.signOut();

    // Clear Firestore data before each test
    await clearFirestoreData();
  });

  tearDown(() {
    // Close blocs to reset state
    groupNoteBloc.close();
    groupNoteBloc = GroupNoteBloc(groupNoteRepository: groupNoteRepository);
  });

  // Helper function to create a test group
  Future<String> createTestGroup() async {
    // Sign up and sign in needed for group creation
    await signUpAndSignIn(
      authService: authService,
      email: testEmail,
      password: testPassword,
    );

    // Create test group
    final groupId = await groupNoteRepository.createGroup(
      testGroupName,
      [], // Empty member list for test purposes
    );
    return groupId;
  }

  group('Group Note Integration Test with Authentication and Firestore', () {
    test(
      'Full Group Note Flow: Sign up -> Sign in -> Create Group -> Add Note -> Update Note -> Delete Note',
      () async {
        // Sign up and sign in
        await signUpAndSignIn(
          authService: authService,
          email: testEmail,
          password: testPassword,
        );

        // Create test group
        testGroupId = await groupNoteRepository.createGroup(
          testGroupName,
          [], // Empty member list for test purposes
        );
        expect(
          testGroupId.isNotEmpty,
          true,
          reason: 'Group ID should not be empty',
        );

        // Load notes (initially empty)
        groupNoteBloc.add(LoadNotes(testGroupId));

        // Wait for initial load to complete
        await expectLater(
          groupNoteBloc.stream,
          emitsThrough(
            predicate<GroupNoteState>((state) => state.isLoading == false),
          ),
        );

        // Create a test note
        final testNote = GroupNoteModel(
          id: '',
          groupId: testGroupId,
          title: 'Test Note Title',
          content: 'Test note content for integration testing',
          createdBy: FirebaseAuth.instance.currentUser!.uid,
          createdAt: DateTime.now(),
          tags: ['Note'],
          comments: [],
        );

        // Add note
        groupNoteBloc.add(AddNote(testNote));

        // Wait for note creation to complete
        await Future.delayed(const Duration(seconds: 2));

        // Load notes again to see the new note
        groupNoteBloc.add(LoadNotes(testGroupId));

        // Check that note was added
        await expectLater(
          groupNoteBloc.stream,
          emitsThrough(
            predicate<GroupNoteState>((state) {
              debugPrint('Notes length: ${state.notes.length}');
              return state.isLoading == false &&
                  state.notes.isNotEmpty &&
                  state.notes.any(
                    (note) =>
                        note.title == 'Test Note Title' &&
                        note.content ==
                            'Test note content for integration testing',
                  );
            }),
          ),
        );

        // Get the note ID for update and delete operations
        late final String noteId;
        final state = groupNoteBloc.state;
        expect(
          state.notes.isNotEmpty,
          true,
          reason: 'Notes list should not be empty',
        );
        noteId = state.notes.first.id;

        // Update note
        final updatedNote = GroupNoteModel(
          id: noteId,
          groupId: testGroupId,
          title: 'Updated Test Note Title',
          content: 'Updated test note content',
          createdBy: FirebaseAuth.instance.currentUser!.uid,
          createdAt: state.notes.first.createdAt,
          tags: ['Note', 'Updated'],
          comments: [],
        );
        groupNoteBloc.add(EditNote(updatedNote));

        // Wait for update to complete
        await Future.delayed(const Duration(seconds: 2));

        // Reload notes to see the updated note
        groupNoteBloc.add(LoadNotes(testGroupId));

        // Check that note was updated
        await expectLater(
          groupNoteBloc.stream,
          emitsThrough(
            predicate<GroupNoteState>((state) {
              return state.notes.any(
                (note) =>
                    note.id == noteId &&
                    note.title == 'Updated Test Note Title' &&
                    note.content == 'Updated test note content' &&
                    note.tags.contains('Updated'),
              );
            }),
          ),
        );

        // Delete note
        groupNoteBloc.add(DeleteNote(noteId, groupId: testGroupId));

        // Wait for delete to complete
        await Future.delayed(const Duration(seconds: 2));

        // Reload notes to confirm deletion
        groupNoteBloc.add(LoadNotes(testGroupId));

        // Check that note was deleted
        await expectLater(
          groupNoteBloc.stream,
          emitsThrough(
            predicate<GroupNoteState>((state) {
              return state.notes.isEmpty ||
                  !state.notes.any((note) => note.id == noteId);
            }),
          ),
        );
      },
    );

    test('Add and filter notes by tag', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Create test group
      testGroupId = await groupNoteRepository.createGroup(
        testGroupName,
        [], // Empty member list for test purposes
      );

      // Create notes with different tags
      final noteWithExpenseTag = GroupNoteModel(
        id: '',
        groupId: testGroupId,
        title: 'Expense Note',
        content: 'This is an expense-related note',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        tags: ['Expense'],
        comments: [],
      );

      final noteWithGoalTag = GroupNoteModel(
        id: '',
        groupId: testGroupId,
        title: 'Goal Note',
        content: 'This is a goal-related note',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        tags: ['Goal'],
        comments: [],
      );

      // Add notes
      groupNoteBloc.add(AddNote(noteWithExpenseTag));
      await Future.delayed(const Duration(seconds: 1));
      groupNoteBloc.add(AddNote(noteWithGoalTag));
      await Future.delayed(const Duration(seconds: 1));

      // Load all notes
      groupNoteBloc.add(LoadNotes(testGroupId));

      // Verify both notes are loaded
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            debugPrint('Notes loaded: ${state.notes.length}');
            return state.notes.length == 2;
          }),
        ),
      );

      // Filter by 'Expense' tag
      groupNoteBloc.add(const FilterNotes('Expense'));

      // Verify only expense note is shown
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            debugPrint('Filtered notes: ${state.filteredNotes.length}');
            return state.filteredNotes.length == 1 &&
                state.filteredNotes.first.title == 'Expense Note';
          }),
        ),
      );

      // Clear filter
      groupNoteBloc.add(const FilterNotes(null));

      // Verify all notes are shown again
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            return state.filteredNotes.length == 2;
          }),
        ),
      );
    });

    test('Search notes by content', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Create test group
      testGroupId = await groupNoteRepository.createGroup(
        testGroupName,
        [], // Empty member list for test purposes
      );

      // Create notes with different content
      final note1 = GroupNoteModel(
        id: '',
        groupId: testGroupId,
        title: 'Apple Products',
        content: 'Note about iPhone and iPad',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        tags: ['Note'],
        comments: [],
      );

      final note2 = GroupNoteModel(
        id: '',
        groupId: testGroupId,
        title: 'Android Products',
        content: 'Note about Samsung and Pixel',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        tags: ['Note'],
        comments: [],
      );

      // Add notes
      groupNoteBloc.add(AddNote(note1));
      await Future.delayed(const Duration(seconds: 1));
      groupNoteBloc.add(AddNote(note2));
      await Future.delayed(const Duration(seconds: 1));

      // Load all notes
      groupNoteBloc.add(LoadNotes(testGroupId));

      // Verify both notes are loaded
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            return state.notes.length == 2;
          }),
        ),
      );

      // Enable search mode
      groupNoteBloc.add(const ToggleSearch(true));

      // Search for "iPhone"
      groupNoteBloc.add(const SearchNotes('iPhone'));

      // Verify only Apple note is shown
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            return state.filteredNotes.length == 1 &&
                state.filteredNotes.first.title == 'Apple Products';
          }),
        ),
      );

      // Clear search
      groupNoteBloc.add(const SearchNotes(''));

      // Verify all notes are shown again
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            return state.filteredNotes.length == 2;
          }),
        ),
      );

      // Disable search mode
      groupNoteBloc.add(const ToggleSearch(false));
    });

    test('Add comment to note', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Create test group
      testGroupId = await groupNoteRepository.createGroup(
        testGroupName,
        [], // Empty member list for test purposes
      );

      // Create a note
      final testNote = GroupNoteModel(
        id: '',
        groupId: testGroupId,
        title: 'Note for Comments',
        content: 'This note will receive comments',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: DateTime.now(),
        tags: ['Note'],
        comments: [],
      );

      // Add note
      groupNoteBloc.add(AddNote(testNote));

      // Wait for note creation to complete
      await Future.delayed(const Duration(seconds: 2));

      // Load notes to get the note ID
      groupNoteBloc.add(LoadNotes(testGroupId));

      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            return state.notes.isNotEmpty;
          }),
        ),
      );

      // Get the note ID
      final noteId = groupNoteBloc.state.notes.first.id;

      // Create a comment
      final comment = CommentModel(
        userId: FirebaseAuth.instance.currentUser!.uid,
        content: 'This is a test comment',
        createdAt: DateTime.now(),
      );

      // Add the comment
      groupNoteBloc.add(AddComment(noteId, comment, groupId: testGroupId));

      // Wait for comment addition to complete
      await Future.delayed(const Duration(seconds: 2));

      // Reload notes to see the comment
      groupNoteBloc.add(LoadNotes(testGroupId));

      // Check that comment was added
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            final noteWithComment = state.notes.firstWhere(
              (note) => note.id == noteId,
              orElse: () => testNote,
            );
            debugPrint('Comments count: ${noteWithComment.comments.length}');
            return noteWithComment.comments.isNotEmpty &&
                noteWithComment.comments.first.content ==
                    'This is a test comment';
          }),
        ),
      );
    });

    test('Cannot access group notes without authentication', () async {
      // Create a group ID format without authentication
      const unauthenticatedGroupId = 'fake-group-id';

      // Try to load notes when not logged in
      groupNoteBloc.add(LoadNotes(unauthenticatedGroupId));

      // Expect an error state
      await expectLater(
        groupNoteBloc.stream,
        emitsThrough(
          predicate<GroupNoteState>((state) {
            debugPrint('Group note state emitted: ${state.error != null}');
            return state.error != null;
          }),
        ),
      );
    });
  });
}
