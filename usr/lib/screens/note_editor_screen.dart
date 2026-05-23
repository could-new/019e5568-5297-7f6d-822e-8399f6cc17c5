import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../models/note_version.dart';
import '../providers/app_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  Timer? _autosaveTimer;
  bool _isSaving = false;
  
  final List<String> _undoHistory = [];
  final List<String> _redoHistory = [];
  
  late String _currentContent;
  String? _noteId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? 'Untitled Note');
    _currentContent = widget.note?.content ?? '';
    _contentController = TextEditingController(text: _currentContent);
    _noteId = widget.note?.id;
    
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (_contentController.text != _currentContent) {
      _undoHistory.add(_currentContent);
      _redoHistory.clear();
      _currentContent = _contentController.text;
      
      // Debounce autosave
      _autosaveTimer?.cancel();
      _autosaveTimer = Timer(const Duration(seconds: 2), _saveNote);
      setState(() {});
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      _redoHistory.add(_currentContent);
      _currentContent = _undoHistory.removeLast();
      
      _contentController.removeListener(_onContentChanged);
      _contentController.text = _currentContent;
      _contentController.selection = TextSelection.collapsed(offset: _currentContent.length);
      _contentController.addListener(_onContentChanged);
      setState(() {});
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      _undoHistory.add(_currentContent);
      _currentContent = _redoHistory.removeLast();
      
      _contentController.removeListener(_onContentChanged);
      _contentController.text = _currentContent;
      _contentController.selection = TextSelection.collapsed(offset: _currentContent.length);
      _contentController.addListener(_onContentChanged);
      setState(() {});
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) return;
    
    setState(() => _isSaving = true);
    
    final repo = ref.read(noteRepositoryProvider);
    final title = _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text;
    final content = _contentController.text;
    
    if (_noteId == null) {
      // Create new note
      final newNote = await repo.createNote(title, content);
      if (newNote != null) {
        _noteId = newNote.id;
      }
    } else {
      // Update existing note
      await repo.updateNote(_noteId!, title, content);
    }
    
    ref.invalidate(notesProvider);
    
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showVersions() async {
    if (_noteId == null) return;
    
    final repo = ref.read(noteRepositoryProvider);
    final versions = await repo.getNoteVersions(_noteId!);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: versions.length,
          itemBuilder: (context, index) {
            final version = versions[index];
            return ListTile(
              title: Text('Version from ${version.timestamp}'),
              subtitle: Text(version.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: ElevatedButton(
                child: const Text('Restore'),
                onPressed: () {
                  _contentController.text = version.content;
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      }
    );
  }

  int get _wordCount {
    if (_contentController.text.trim().isEmpty) return 0;
    return _contentController.text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Note Title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          onChanged: (_) {
            _autosaveTimer?.cancel();
            _autosaveTimer = Timer(const Duration(seconds: 2), _saveNote);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoHistory.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoHistory.isNotEmpty ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _noteId != null ? _showVersions : null,
          ),
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start typing...',
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Text('$_wordCount words', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (_isSaving) Text('Saving...', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}