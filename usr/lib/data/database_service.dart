import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note_model.dart';
import '../models/note_version.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
CREATE TABLE notes_meta (
  id $idType,
  fileName $textType,
  filePath $textType,
  isFavorite $boolType,
  tags $textNullableType,
  lastModified $integerType,
  wordCount $integerType
)
''');

    await db.execute('''
CREATE TABLE note_versions (
  id $idType,
  noteId $textType,
  content $textType,
  timestamp $integerType
)
''');
  }

  Future<void> saveNoteMeta(NoteModel note) async {
    final db = await instance.database;
    await db.insert(
      'notes_meta',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<NoteModel?> getNoteMeta(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes_meta',
      columns: ['id', 'fileName', 'filePath', 'isFavorite', 'tags', 'lastModified', 'wordCount'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NoteModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<NoteModel>> getAllNoteMetas() async {
    final db = await instance.database;
    final result = await db.query('notes_meta');
    return result.map((json) => NoteModel.fromMap(json)).toList();
  }

  Future<void> deleteNoteMeta(String id) async {
    final db = await instance.database;
    await db.delete(
      'notes_meta',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'note_versions',
      where: 'noteId = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveNoteVersion(NoteVersion version) async {
    final db = await instance.database;
    await db.insert(
      'note_versions',
      version.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'note_versions',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'timestamp DESC',
    );
    return result.map((json) => NoteVersion.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
