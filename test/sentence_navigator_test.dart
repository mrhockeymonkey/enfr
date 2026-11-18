import 'package:enfr/models/subtitle_cue.dart';
import 'package:enfr/services/sentence_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

Duration s(double v) => Duration(milliseconds: (v * 1000).round());

final cues = [
  SubtitleCue(start: s(1), end: s(3), text: 'a'),
  SubtitleCue(start: s(5), end: s(8), text: 'b'),
  SubtitleCue(start: s(10), end: s(12), text: 'c'),
];

void main() {
  group('activeIndex', () {
    test('null before the first cue', () {
      expect(activeIndex(cues, s(0.5)), isNull);
    });
    test('inside a cue', () {
      expect(activeIndex(cues, s(1)), 0);
      expect(activeIndex(cues, s(6)), 1);
    });
    test('in a gap returns the last started cue', () {
      expect(activeIndex(cues, s(4)), 0);
    });
    test('after the last cue', () {
      expect(activeIndex(cues, s(100)), 2);
    });
    test('empty list', () {
      expect(activeIndex(const [], s(1)), isNull);
    });
  });

  test('isInside', () {
    expect(isInside(cues[0], s(2)), isTrue);
    expect(isInside(cues[0], s(3)), isFalse);
  });

  group('previousTarget', () {
    test('restarts current cue when well into it', () {
      expect(previousTarget(cues, s(7)), s(5));
    });
    test('goes to previous cue near the start of current', () {
      expect(previousTarget(cues, s(5.5)), s(1));
    });
    test('stays on first cue', () {
      expect(previousTarget(cues, s(1.2)), s(1));
    });
    test('before first cue goes to first cue', () {
      expect(previousTarget(cues, s(0)), s(1));
    });
    test('empty list', () {
      expect(previousTarget(const [], s(1)), isNull);
    });
  });

  group('nextTarget', () {
    test('before first cue goes to first', () {
      expect(nextTarget(cues, s(0)), s(1));
    });
    test('goes to the following cue', () {
      expect(nextTarget(cues, s(2)), s(5));
      expect(nextTarget(cues, s(4)), s(5));
    });
    test('null on last cue', () {
      expect(nextTarget(cues, s(11)), isNull);
    });
  });
}
