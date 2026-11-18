import 'package:enfr/services/subtitle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  group('parseSubtitles', () {
    test('parses basic SRT with multi-line cues', () {
      const srt = '''1
00:00:01,000 --> 00:00:03,500
Bonjour à tous.

2
00:00:04,000 --> 00:00:06,250
Comment allez-vous ?
Très bien.
''';
      final cues = parseSubtitles(srt);
      expect(cues, hasLength(2));
      expect(cues[0].start, ms(1000));
      expect(cues[0].end, ms(3500));
      expect(cues[0].text, 'Bonjour à tous.');
      expect(cues[1].text, 'Comment allez-vous ?\nTrès bien.');
      expect(cues[1].end, ms(6250));
    });

    test('handles BOM and CRLF line endings', () {
      const srt = '﻿1\r\n00:00:01,000 --> 00:00:02,000\r\nSalut\r\n\r\n'
          '2\r\n00:00:03,000 --> 00:00:04,000\r\nÇa va ?\r\n';
      final cues = parseSubtitles(srt);
      expect(cues.map((c) => c.text), ['Salut', 'Ça va ?']);
    });

    test('parses WebVTT with header, NOTE, settings and short timestamps', () {
      const vtt = '''WEBVTT - Example

NOTE this is a comment
with --> arrows inside

STYLE
::cue { color: red }

intro
00:01.000 --> 00:02.500 align:start position:10%
<v Marie>Bonjour</v>

01:00:00.000 --> 01:00:01.000
<i>Fin</i> &amp; au revoir
''';
      final cues = parseSubtitles(vtt);
      expect(cues, hasLength(2));
      expect(cues[0].start, ms(1000));
      expect(cues[0].end, ms(2500));
      expect(cues[0].text, 'Bonjour');
      expect(cues[1].start, const Duration(hours: 1));
      expect(cues[1].text, 'Fin & au revoir');
    });

    test('strips ASS-style override tags', () {
      const srt = '1\n00:00:01,000 --> 00:00:02,000\n{\\an8}En haut\n';
      expect(parseSubtitles(srt).single.text, 'En haut');
    });

    test('sorts out-of-order cues and skips malformed blocks', () {
      const srt = '''2
00:00:05,000 --> 00:00:06,000
Deux

garbage block

3
not a timing --> line
Trois

1
00:00:01,000 --> 00:00:02,000
Un

4
00:00:07,000 --> 00:00:08,000
''';
      final cues = parseSubtitles(srt);
      expect(cues.map((c) => c.text), ['Un', 'Deux']);
    });

    test('returns empty for empty input', () {
      expect(parseSubtitles(''), isEmpty);
    });
  });
}
