class Note {
  final String id;
  final String title;
  final String content;
  final int imageCount;
  final bool isPinned;
  final bool isArchived;
  final List<String> tags;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.imageCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.tags = const [],
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    int? imageCount,
    bool? isPinned,
    bool? isArchived,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageCount: imageCount ?? this.imageCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
    );
  }
}