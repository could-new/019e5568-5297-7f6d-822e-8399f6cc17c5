import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_service.dart';
import '../data/note_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return NoteRepository(dbService);
});

final selectedFolderProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('selected_folder');
});
