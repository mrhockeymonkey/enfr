import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter_test/flutter_test.dart';

const _parler = {
  'P': ['parle', 'parles', 'parle', 'parlons', 'parlez', 'parlent'],
  'S': ['parle', 'parles', 'parle', 'parlions', 'parliez', 'parlent'],
  'Y': ['NA', 'parle', 'NA', 'parlons', 'parlez', 'NA'],
  'I': ['parlais', 'parlais', 'parlait', 'parlions', 'parliez', 'parlaient'],
  'G': ['parlant'],
  'K': ['parlé', 'parlés', 'parlée', 'parlées'],
  'J': ['parlai', 'parlas', 'parla', 'parlâmes', 'parlâtes', 'parlèrent'],
  'T': [
    'parlasse',
    'parlasses',
    'parlât',
    'parlassions',
    'parlassiez',
    'parlassent'
  ],
  'F': [
    'parlerai',
    'parleras',
    'parlera',
    'parlerons',
    'parlerez',
    'parleront'
  ],
  'C': [
    'parlerais',
    'parlerais',
    'parlerait',
    'parlerions',
    'parleriez',
    'parleraient'
  ],
  'W': ['parler'],
  'zipf': 5.52,
};

void main() {
  group('Verb.fromJson', () {
    test('parses all nine quizzable tenses', () {
      final verb = Verb.fromJson('parler', VerbTier.essential, _parler)!;

      expect(verb.infinitive, 'parler');
      expect(verb.tier, VerbTier.essential);
      expect(verb.zipf, 5.52);
      for (final tense in VerbTense.values) {
        expect(verb.hasTense(tense), isTrue, reason: tense.name);
      }
      expect(verb.form(VerbTense.present, 3), 'parlons');
      expect(verb.form(VerbTense.futur, 0), 'parlerai');
      expect(verb.form(VerbTense.pastParticiple, 3), 'parlées');
    });

    test('maps NA imperative slots to null', () {
      final verb = Verb.fromJson('parler', VerbTier.essential, _parler)!;

      expect(verb.form(VerbTense.imperatif, 0), isNull);
      expect(verb.form(VerbTense.imperatif, 1), 'parle');
      expect(verb.slotsFor(VerbTense.imperatif), [1, 3, 4]);
    });

    test('reports a missing tense as absent', () {
      final json = Map<String, dynamic>.from(_parler)..remove('Y');
      final verb = Verb.fromJson('pouvoir', VerbTier.essential, json)!;

      expect(verb.hasTense(VerbTense.imperatif), isFalse);
      expect(verb.form(VerbTense.imperatif, 1), isNull);
      expect(verb.slotsFor(VerbTense.imperatif), isEmpty);
    });

    test('returns null for entries with no conjugation data', () {
      expect(
        Verb.fromJson('voilà', VerbTier.essential, {'zipf': 5.25}),
        isNull,
      );
    });

    test('ignores arrays of the wrong length', () {
      final json = Map<String, dynamic>.from(_parler)
        ..['P'] = ['parle', 'parles'];
      final verb = Verb.fromJson('parler', VerbTier.essential, json)!;

      expect(verb.hasTense(VerbTense.present), isFalse);
      expect(verb.hasTense(VerbTense.futur), isTrue);
    });
  });
}
