class NoteModel {
  final String path;
  final String name;
  final String content;
  final DateTime lastModified;
  final bool isFavorite;
  final List<String> tags;

  NoteModel({
    required this.path,
    required this.name,
    required this.content,
    required this.lastModified,
    this.isFavorite = false,
    this.tags = const [],
  });

  NoteModel copyWith({
    String? path,
    String? name,
    String? content,
    DateTime? lastModified,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return NoteModel(
      path: path ?? this.path,
      name: name ?? this.name,
      content: content ?? this.content,
      lastModified: lastModified ?? this.lastModified,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }
}
