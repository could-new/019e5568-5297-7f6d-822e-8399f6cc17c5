class NoteVersion {
  final String id;
  final String filePath;
  final String content;
  final DateTime savedAt;

  NoteVersion({
    required this.id,
    required this.filePath,
    required this.content,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'content': content,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory NoteVersion.fromMap(Map<String, dynamic> map) {
    return NoteVersion(
      id: map['id'],
      filePath: map['file_path'],
      content: map['content'],
      savedAt: DateTime.parse(map['saved_at']),
    );
  }
}
