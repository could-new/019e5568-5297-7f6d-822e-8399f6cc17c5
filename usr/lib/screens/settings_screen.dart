import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _selectFolder(WidgetRef ref) async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('selected_folder', result);
      ref.read(selectedFolderProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFolder = ref.watch(selectedFolderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Notes Directory'),
            subtitle: Text(currentFolder ?? 'No folder selected'),
            trailing: const Icon(Icons.folder_open),
            onTap: () => _selectFolder(ref),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Select a directory to store and read your text files. Changes to files in this directory will be tracked.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
