import 'package:enfr/models/check_response.dart';
import 'package:enfr/services/check_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Splits [json] into chunks of [size] characters, so boundaries land inside
/// keys, escapes and multi-byte characters.
Stream<String> chunked(String json, int size) async* {
  for (var i = 0; i < json.length; i += size) {
    yield json.substring(i, i + size > json.length ? json.length : i + size);
  }
}

const correctedJson = r'''{
  "answer": "Correction :\n**« Ils ont perdu les chiens. »**",
  "explanation": "**ils** → sujet pluriel\n**ont** → auxiliaire \"avoir\" é",
  "suggestion": "",
  "meaning": "They lost the dogs."
}''';

const correctJson = r'''{
  "answer": "**« On va aller à la plage. »** est correct. ✅",
  "explanation": "",
  "suggestion": "On dirait : « On va à la plage. »",
  "meaning": "We’re going to the beach."
}''';

void main() {
  test('schema properties and required fields match CheckSection', () {
    final names = [for (final s in CheckSection.values) s.name];
    expect((checkResponseSchema['properties'] as Map).keys, names);
    expect(checkResponseSchema['required'], names);
    expect(checkResponseSchema['additionalProperties'], false);
  });

  for (final size in [1, 3, 7, 1000]) {
    test('parses sections from chunks of $size', () async {
      final reply = CheckReply.fromJsonChunks(chunked(correctedJson, size));
      final response = await reply.done;
      expect(response.answer, 'Correction :\n**« Ils ont perdu les chiens. »**');
      expect(response.explanation,
          '**ils** → sujet pluriel\n**ont** → auxiliaire "avoir" é');
      expect(response.suggestion, '');
      expect(response.meaning, 'They lost the dogs.');
    });
  }

  test('section streams replay to late listeners', () async {
    final reply = CheckReply.fromJsonChunks(chunked(correctedJson, 5));
    await reply.done;
    expect(await reply.section(CheckSection.meaning).join(),
        'They lost the dogs.');
  });

  test('truncated output completes with what arrived', () async {
    final reply = CheckReply.fromJsonChunks(
        chunked(correctedJson.substring(0, correctedJson.indexOf('"suggestion')), 4));
    final response = await reply.done;
    expect(response.answer, 'Correction :\n**« Ils ont perdu les chiens. »**');
    expect(response.meaning, '');
  });

  test('upstream errors reach section streams and done', () async {
    Stream<String> failing() async* {
      yield '{"answer": "Bon';
      throw StateError('network');
    }

    final reply = CheckReply.fromJsonChunks(failing());
    expect(reply.section(CheckSection.answer).join(), throwsStateError);
    expect(reply.done, throwsStateError);
  });

  group('checkMarkdown', () {
    test('renders a corrected sentence', () async {
      final md = await checkMarkdown(
              CheckReply.fromJsonChunks(chunked(correctedJson, 3)))
          .join();
      expect(
          md,
          'Correction :\n**« Ils ont perdu les chiens. »**\n\n'
          '**ils** → sujet pluriel\n**ont** → auxiliaire "avoir" é\n\n'
          'Signification : « They lost the dogs. »');
    });

    test('renders a correct sentence without gaps for empty sections',
        () async {
      final md =
          await checkMarkdown(CheckReply.fromJsonChunks(chunked(correctJson, 2)))
              .join();
      expect(
          md,
          '**« On va aller à la plage. »** est correct. ✅\n\n'
          'On dirait : « On va à la plage. »\n\n'
          'Signification : « We’re going to the beach. »');
    });

    test('keeps section order when fields arrive out of order', () async {
      const json = '{"meaning": "Hi.", "suggestion": "", '
          '"explanation": "", "answer": "Salut."}';
      final md =
          await checkMarkdown(CheckReply.fromJsonChunks(chunked(json, 4)))
              .join();
      expect(md, 'Salut.\n\nSignification : « Hi. »');
    });
  });
}
