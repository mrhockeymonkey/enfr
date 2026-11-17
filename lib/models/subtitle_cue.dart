/// One timed subtitle line (usually a sentence) from an SRT or WebVTT file.
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  @override
  String toString() => 'SubtitleCue($start → $end: $text)';
}
