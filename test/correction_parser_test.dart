import 'package:enfr/models/correction.dart';
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

    test('parses item with status=active', () {
      final result = parseCorrections(
        '<text>je ai</text><correction>j\'ai</correction><status>active</status>',
      );
      expect(result, hasLength(1));
      expect(result.first.status, CorrectionStatus.active);
    });

    test('parses item with status=fixed', () {
      final result = parseCorrections(
        '<text>je ai</text><correction>j\'ai</correction><status>fixed</status>',
      );
      expect(result, hasLength(1));
      expect(result.first.status, CorrectionStatus.fixed);
    });

    test('defaults to active when status tag is missing', () {
      final result = parseCorrections(
        '<text>je ai</text><correction>j\'ai</correction>',
      );
      expect(result, hasLength(1));
      expect(result.first.status, CorrectionStatus.active);
    });

    test('defaults to active when status value is malformed', () {
      final result = parseCorrections(
        '<text>je ai</text><correction>j\'ai</correction><status>donezo</status>',
      );
      expect(result, hasLength(1));
      expect(result.first.status, CorrectionStatus.active);
    });

    test('parses a mixed list preserving order and statuses', () {
      final raw = '''
<text>je ai</text><correction>j'ai</correction><status>fixed</status>
<text>il s'appele</text><correction>il s'appelle</correction><status>active</status>
<text>Hier je mange</text><correction>Hier j'ai mangé</correction>
''';
      final result = parseCorrections(raw);
      expect(result, hasLength(3));
      expect(result[0].originalText, 'je ai');
      expect(result[0].status, CorrectionStatus.fixed);
      expect(result[1].originalText, "il s'appele");
      expect(result[1].status, CorrectionStatus.active);
      expect(result[2].originalText, 'Hier je mange');
      expect(result[2].status, CorrectionStatus.active);
    });

    test('tolerates whitespace inside the status tag', () {
      final result = parseCorrections(
        '<text>je ai</text><correction>j\'ai</correction><status>  fixed  </status>',
      );
      expect(result, hasLength(1));
      expect(result.first.status, CorrectionStatus.fixed);
    });
  });

  group('Correction.fromJson', () {
    test('defaults to active when status key is missing (legacy data)', () {
      final c = Correction.fromJson({
        'originalText': 'je ai',
        'suggestedText': "j'ai",
      });
      expect(c.status, CorrectionStatus.active);
    });

    test('reads status when present', () {
      final c = Correction.fromJson({
        'originalText': 'je ai',
        'suggestedText': "j'ai",
        'status': 'fixed',
      });
      expect(c.status, CorrectionStatus.fixed);
    });
  });
}
