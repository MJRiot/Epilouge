import '../../../core/database/database_helper.dart';
import '../domain/note_model.dart';

class NoteRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<String> createNote(Note note) async {
    return await dbHelper.create(note);
  }

  Future<List<Note>> getAllNotes() async {
    return await dbHelper.readAllNotes();
  }

  Future<Note> getNote(String id) async {
    return await dbHelper.readNote(id);
  }

  Future<int> updateNote(Note note) async {
    return await dbHelper.update(note);
  }

  Future<int> deleteNote(String id) async {
    return await dbHelper.delete(id);
  }
}
