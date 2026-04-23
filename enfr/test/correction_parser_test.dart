import 'package:enfr/services/correction_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCorrections', () {
    test('returns empty list for empty input', () {
      expect(parseCorrections(''), isEmpty);
    });

    test('returns empty list when no tags are present', () {
      expect(parseCorrections('the entry is correct'), isEmpty);
    });

    test('parses a single pair on one line', () {
      final result = parseCorrections(
        '<text>je ai un chien</text><correction>j\'ai un chien</correction>',
      );
      expect(result, hasLength(1));
      expect(result.first.originalText, 'je ai un chien');
      expect(result.first.suggestedText, "j'ai un chien");
    });

    test('parses multiple pairs separated by newlines', () {
      final raw = '''
<text>je ai un chien</text><correction>j'ai un chien</correction>
<text>il s'appele rex</text><correction>il s'appelle Rex</correction>
''';
      final result = parseCorrections(raw);
      expect(result, hasLength(2));
      expect(result[0].originalText, 'je ai un chien');
      expect(result[0].suggestedText, "j'ai un chien");
      expect(result[1].originalText, "il s'appele rex");
      expect(result[1].suggestedText, "il s'appelle Rex");
    });

    test('tolerates whitespace and newlines between text and correction tags',
        () {
      final raw = '''
<text>je ai un chien</text>
   <correction>j'ai un chien</correction>
''';
      final result = parseCorrections(raw);
      expect(result, hasLength(1));
      expect(result.first.originalText, 'je ai un chien');
      expect(result.first.suggestedText, "j'ai un chien");
    });

    test('handles multi-line content within tags', () {
      final raw = '''
<text>premier ligne
deuxieme ligne</text><correction>première ligne
deuxième ligne</correction>
''';
      final result = parseCorrections(raw);
      expect(result, hasLength(1));
      expect(result.first.originalText, 'premier ligne\ndeuxieme ligne');
      expect(result.first.suggestedText, 'première ligne\ndeuxième ligne');
    });
  });
}
