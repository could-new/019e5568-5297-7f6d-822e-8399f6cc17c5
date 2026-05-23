import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final isInitialized = ref.watch(isInitializedProvider).value ?? false;

    if (!isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notes')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please select a notes folder in Settings.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: notesAsync.when(
        data: (notes) {
          // Filter notes
          var filteredNotes = notes.where((note) {
            final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  note.content.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesTag = _selectedTag == null || note.tags.contains(_selectedTag);
            return matchesSearch && matchesTag;
          }).toList();

          // Sort: favorites first, then by modified date
          filteredNotes.sort((a, b) {
            if (a.isFavorite && !b.isFavorite) return -1;
            if (!a.isFavorite && b.isFavorite) return 1;
            return b.lastModified.compareTo(a.lastModified);
          });

          // Extract all unique tags
          final allTags = notes.expand((n) => n.tags).toSet().toList()..sort();

          return Column(
            children: [
              if (allTags.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: allTags.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedTag == null,
                            onSelected: (selected) => setState(() => _selectedTag = null),
                          ),
                        );
                      }
                      final tag = allTags[index - 1];
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: FilterChip(
                          label: Text('#$tag'),
                          selected: _selectedTag == tag,
                          onSelected: (selected) => setState(() => _selectedTag = selected ? tag : null),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: filteredNotes.isEmpty
                    ? const Center(child: Text('No notes found.'))
                    : ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat.yMMMd().add_jm().format(note.lastModified),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${note.wordCount} words',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  note.isFavorite ? Icons.star : Icons.star_border,
                                  color: note.isFavorite ? Colors.amber : null,
                                ),
                                onPressed: () {
                                  ref.read(noteRepositoryProvider).toggleFavorite(note.id, !note.isFavorite);
                                  ref.invalidate(notesProvider);
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NoteEditorScreen(note: note),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}