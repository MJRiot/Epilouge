import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/note_repository.dart';
import '../../domain/note_model.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesListProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(() {
  return NotesNotifier();
});

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repository = ref.read(noteRepositoryProvider);
    return repository.getAllNotes();
  }

  Future<void> addNote(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.createNote(note);
    ref.invalidateSelf();
  }

  Future<void> updateNote(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNote(note);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(id);
    ref.invalidateSelf();
  }

  /// Flips the pinned state of [note] and persists it.
  /// Does NOT touch updatedAt, so pinning doesn't reorder
  /// the note within its pinned/unpinned group.
  Future<void> togglePin(Note note) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNote(note.copyWith(pinned: !note.pinned));
    ref.invalidateSelf();
  }

  /// Sets ([at] = a DateTime) or clears ([at] = null) the reminder on [note].
  Future<void> setReminder(Note note, DateTime? at) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNote(note.copyWith(reminderAt: at));
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notesAsync = ref.watch(notesListProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  return notesAsync.when(
    data: (notes) {
      if (selectedCategory == 'All') {
        return notes;
      }
      return notes.where((note) => note.category == selectedCategory).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
