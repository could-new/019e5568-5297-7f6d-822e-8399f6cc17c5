import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/note_version.dart';
import 'database_service.dart';

class NoteRepository {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  Future<List<NoteModel>> loadNotesFromDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }

    final List<NoteModel> notes = [];
    final files = directory.listSync().where((entity) => entity is File && entity.path.endsWith('.txt'));

    for (var file in files) {
      final f = File(file.path);
      final fileName = f.path.split(Platform.pathSeparator).last;
      
      // Try to find existing meta
      final allMetas = await _db.getAllNoteMetas();
      NoteModel? existingMeta;
      try {
        existingMeta = allMetas.firstWhere((m) => m.filePath == f.path);
      } catch (e) {
        existingMeta = null;
      }

      if (existingMeta != null) {
        notes.add(existingMeta);
      } else {
        final content = await f.readAsString();
        final stat = await f.stat();
        final newNote = NoteModel(
          id: _uuid.v4(),
          fileName: fileName,
          filePath: f.path,
          lastModified: stat.modified,
          wordCount: _countWords(content),
        );
        await _db.saveNoteMeta(newNote);
        notes.add(newNote);
      }
    }
    return notes;
  }

  Future<String> readNoteContent(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  Future<void> saveNoteContent(NoteModel note, String content, {bool isManualSave = false}) async {
    final file = File(note.filePath);
    await file.writeAsString(content);

    final updatedNote = note.copyWith(
      lastModified: DateTime.now(),
      wordCount: _countWords(content),
    );
    await _db.saveNoteMeta(updatedNote);

    if (isManualSave) {
      final version = NoteVersion(
        id: _uuid.v4(),
        noteId: note.id,
        content: content,
        timestamp: DateTime.now(),
      );
      await _db.saveNoteVersion(version);
    }
  }

  Future<void> toggleFavorite(NoteModel note) async {
    final updated = note.copyWith(isFavorite: !note.isFavorite);
    await _db.saveNoteMeta(updated);
  }

  Future<void> updateTags(NoteModel note, List<String> tags) async {
    final updated = note.copyWith(tags: tags);
    await _db.saveNoteMeta(updated);
  }

  Future<List<NoteVersion>> getVersions(String noteId) async {
    return await _db.getNoteVersions(noteId);
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
