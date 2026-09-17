import 'package:enfr/models/auxiliary.dart';
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
  'meta': {'pronominal': false, 'auxiliary': 'avoir'},
};

const _partir = {
  'P': ['pars', 'pars', 'part', 'partons', 'partez', 'partent'],
  'K': ['parti', 'partis', 'partie', 'parties'],
  'zipf': 5.1,
  'meta': {'pronominal': false, 'auxiliary': 'être'},
};

const _seLever = {
  'P': [
    'me lève',
    'te lèves',
    'se lève',
    'nous levons',
    'vous levez',
    'se lèvent'
  ],
  'Y': ['NA', 'lève-toi', 'NA', 'levons-nous', 'levez-vous', 'NA'],
  'K': ['levé', 'levés', 'levée', 'levées'],
  'zipf': 4.54,
  'meta': {'pronominal': true, 'auxiliary': 'être'},
};

const _falloir = {
  'P': ['NA', 'NA', 'faut', 'NA', 'NA', 'NA'],
  'K': ['fallu', 'NA', 'NA', 'NA'],
  'zipf': 4.43,
  'meta': {'pronominal': false, 'auxiliary': 'avoir'},
};

void main() {
  group('Verb.fromJson', () {
    test('parses all ten quizzable tenses', () {
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

    test('reads the auxiliary and pronominal flag from meta', () {
      final parler = Verb.fromJson('parler', VerbTier.essential, _parler)!;
      final partir = Verb.fromJson('partir', VerbTier.essential, _partir)!;
      final seLever = Verb.fromJson('se lever', VerbTier.common, _seLever)!;

      expect(parler.auxiliary, Auxiliary.avoir);
      expect(parler.pronominal, isFalse);
      expect(parler.participleAgrees, isFalse);
      expect(partir.auxiliary, Auxiliary.etre);
      expect(partir.participleAgrees, isTrue);
      expect(seLever.pronominal, isTrue);
      expect(seLever.auxiliary, Auxiliary.etre);
      expect(seLever.form(VerbTense.present, 0), 'me lève');
      expect(seLever.form(VerbTense.imperatif, 1), 'lève-toi');
    });

    test('defaults to avoir when meta is missing', () {
      final json = Map<String, dynamic>.from(_parler)..remove('meta');
      final verb = Verb.fromJson('parler', VerbTier.essential, json)!;

      expect(verb.auxiliary, Auxiliary.avoir);
      expect(verb.pronominal, isFalse);
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

  group('passé composé', () {
    test('is built with avoir and never agrees', () {
      final verb = Verb.fromJson('parler', VerbTier.essential, _parler)!;

      expect(verb.form(VerbTense.passeCompose, 0), 'ai parlé');
      expect(verb.form(VerbTense.passeCompose, 3), 'avons parlé');
      expect(
        verb.form(VerbTense.passeCompose, 2,
            agreement: Agreement.feminineSingular),
        'a parlé',
      );
      expect(verb.slotsFor(VerbTense.passeCompose), [0, 1, 2, 3, 4, 5]);
    });

    test('is built with être and agrees with the subject', () {
      final verb = Verb.fromJson('partir', VerbTier.essential, _partir)!;

      expect(verb.form(VerbTense.passeCompose, 0), 'suis parti');
      expect(verb.form(VerbTense.passeCompose, 3), 'sommes partis');
      expect(verb.form(VerbTense.passeCompose, 4), 'êtes partis');
      expect(
        verb.form(VerbTense.passeCompose, 2,
            agreement: Agreement.feminineSingular),
        'est partie',
      );
      expect(
        verb.form(VerbTense.passeCompose, 5,
            agreement: Agreement.femininePlural),
        'sont parties',
      );
    });

    test('is built with the reflexive pronoun for pronominal verbs', () {
      final verb = Verb.fromJson('se lever', VerbTier.common, _seLever)!;

      expect(verb.form(VerbTense.passeCompose, 0), 'me suis levé');
      expect(verb.form(VerbTense.passeCompose, 1), "t'es levé");
      expect(
        verb.form(VerbTense.passeCompose, 2,
            agreement: Agreement.feminineSingular),
        "s'est levée",
      );
      expect(verb.form(VerbTense.passeCompose, 3), 'nous sommes levés');
      expect(
        verb.form(VerbTense.passeCompose, 5,
            agreement: Agreement.femininePlural),
        'se sont levées',
      );
    });

    test('offers the same persons as the present tense', () {
      final verb = Verb.fromJson('falloir', VerbTier.common, _falloir)!;

      expect(verb.hasTense(VerbTense.passeCompose), isTrue);
      expect(verb.slotsFor(VerbTense.passeCompose), [2]);
      expect(verb.form(VerbTense.passeCompose, 2), 'a fallu');
      expect(verb.form(VerbTense.passeCompose, 0), isNull);
    });

    test('is absent without a past participle or present tense', () {
      final noParticiple = Verb.fromJson(
          'parler', VerbTier.essential, Map.from(_parler)..remove('K'))!;
      final noPresent = Verb.fromJson(
          'parler', VerbTier.essential, Map.from(_parler)..remove('P'))!;

      for (final verb in [noParticiple, noPresent]) {
        expect(verb.hasTense(VerbTense.passeCompose), isFalse);
        expect(verb.slotsFor(VerbTense.passeCompose), isEmpty);
        expect(verb.form(VerbTense.passeCompose, 0), isNull);
      }
    });
  });

  group('Agreement', () {
    test('restricts the choices by subject', () {
      expect(Agreement.validFor(0),
          [Agreement.masculineSingular, Agreement.feminineSingular]);
      expect(Agreement.validFor(3),
          [Agreement.masculinePlural, Agreement.femininePlural]);
      expect(Agreement.validFor(4), Agreement.values);
      expect(Agreement.defaultFor(1), Agreement.masculineSingular);
      expect(Agreement.defaultFor(4), Agreement.masculinePlural);
    });
  });
}
