import 'package:enfr/models/subtitle_cue.dart';

final _timing = RegExp(
  r'^\s*((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})\s*-->\s*((?:\d+:)?\d{1,2}:\d{2}[.,]\d{1,3})',
);
final _htmlTag = RegExp(r'<[^>]*>');
final _assTag = RegExp(r'\{\\[^}]*\}');
final _blankLines = RegExp(r'\n\s*\n');

/// Parses SRT or WebVTT subtitle text into cues sorted by start time.
///
/// Malformed blocks are skipped rather than failing the whole file; markup
/// (`<i>`, `<c.x>`, `<v Name>`, `{\an8}`) is stripped so only text remains.
List<SubtitleCue> parseSubtitles(String content) {
  var text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (text.startsWith('﻿')) text = text.substring(1);

  final cues = <SubtitleCue>[];
  for (final block in text.split(_blankLines)) {
    final lines = block.split('\n');
    final timingIndex = lines.indexWhere((l) => l.contains('-->'));
    if (timingIndex < 0) continue; // WEBVTT header, NOTE, STYLE, REGION...
    final first = lines.first.trim();
    if (first.startsWith('NOTE') ||
        first.startsWith('STYLE') ||
        first.startsWith('REGION')) {
      continue;
    }

    final match = _timing.firstMatch(lines[timingIndex]);
    if (match == null) continue;
    final start = _parseTimestamp(match.group(1)!);
    final end = _parseTimestamp(match.group(2)!);
    if (start == null || end == null) continue;

    final body = lines
        .skip(timingIndex + 1)
        .map(_cleanLine)
        .where((l) => l.isNotEmpty)
        .join('\n');
    if (body.isEmpty) continue;

    cues.add(SubtitleCue(start: start, end: end, text: body));
  }

  cues.sort((a, b) => a.start.compareTo(b.start));
  return cues;
}

Duration? _parseTimestamp(String raw) {
  final parts = raw.replaceAll(',', '.').split(':');
  final secParts = parts.last.split('.');
  final seconds = int.tryParse(secParts[0]);
  final fraction = secParts.length > 1 ? secParts[1].padRight(3, '0') : '0';
  final millis = int.tryParse(fraction.substring(0, 3));
  final minutes = int.tryParse(parts[parts.length - 2]);
  final hours = parts.length == 3 ? int.tryParse(parts[0]) : 0;
  if (seconds == null || millis == null || minutes == null || hours == null) {
    return null;
  }
  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: millis,
  );
}

String _cleanLine(String line) => line
    .replaceAll(_htmlTag, '')
    .replaceAll(_assTag, '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .trim();
