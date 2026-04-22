class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;

  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
  });

  JournalEntry copyWith({DateTime? date, String? title, String? content}) =>
      JournalEntry(
        id: id,
        date: date ?? this.date,
        title: title ?? this.title,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        content: j['content'] as String,
      );
}
