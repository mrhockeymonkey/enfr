import 'package:enfr/models/correction.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final List<Correction> corrections;

  JournalEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.corrections = const [],
  });

  JournalEntry copyWith({
    DateTime? date,
    String? title,
    String? content,
    List<Correction>? corrections,
  }) =>
      JournalEntry(
        id: id,
        date: date ?? this.date,
        title: title ?? this.title,
        content: content ?? this.content,
        corrections: corrections ?? this.corrections,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'content': content,
        'corrections': corrections.map((c) => c.toJson()).toList(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        content: j['content'] as String,
        corrections: (j['corrections'] as List?)
                ?.map((e) => Correction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
