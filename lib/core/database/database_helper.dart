import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/notes/domain/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wordsy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // v2: added `pinned` and `reminderAt` columns.
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        imagePaths TEXT,
        pinned INTEGER NOT NULL DEFAULT 0,
        reminderAt INTEGER
      )
    ''');
  }

  /// Migrates databases created before v2 by adding the new columns.
  /// SQLite can't ADD COLUMN with a PRIMARY KEY/NOT NULL without a default,
  /// but both statements below are safe on existing rows:
  ///  - `pinned` defaults to 0 (not pinned) for all existing notes
  ///  - `reminderAt` defaults to NULL (no reminder) for all existing notes
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN reminderAt INTEGER');
    }
  }

  Future<String> create(Note note) async {
    final db = await instance.database;
    await db.insert('notes', note.toMap());
    return note.id;
  }

  Future<Note> readNote(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    // Pinned notes (pinned = 1) sort above unpinned ones (0),
    // then within each group most recently updated first.
    const orderBy = 'pinned DESC, updatedAt DESC';
    final result = await db.query('notes', orderBy: orderBy);
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
