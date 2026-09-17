import 'dart:math';

import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:enfr/services/verb_selector.dart';
import 'package:flutter_test/flutter_test.dart';

Verb _verb(
  String infinitive,
  Map<VerbTense, List<String?>> forms, {
  Auxiliary auxiliary = Auxiliary.avoir,
  bool pronominal = false,
}) =>
    Verb(
      infinitive: infinitive,
      tier: VerbTier.essential,
      zipf: 5,
      forms: forms,
      auxiliary: auxiliary,
      pronominal: pronominal,
    );

final _parler = _verb('parler', {
  VerbTense.present: [
    'parle',
    'parles',
    'parle',
    'parlons',
    'parlez',
    'parlent'
  ],
  VerbTense.futur: [
    'parlerai',
    'parleras',
    'parlera',
    'parlerons',
    'parlerez',
    'parleront'
  ],
  VerbTense.imperatif: [null, 'parle', null, 'parlons', 'parlez', null],
  VerbTense.pastParticiple: ['parlé', 'parlés', 'parlée', 'parlées'],
});

final _finir = _verb('finir', {
  VerbTense.present: [
    'finis',
    'finis',
    'finit',
    'finissons',
    'finissez',
    'finissent'
  ],
});

final _partir = _verb(
  'partir',
  {
    VerbTense.present: ['pars', 'pars', 'part', 'partons', 'partez', 'partent'],
    VerbTense.pastParticiple: ['parti', 'partis', 'partie', 'parties'],
  },
  auxiliary: Auxiliary.etre,
);

final _seLever = _verb(
  'se lever',
  {
    VerbTense.present: [
      'me lève',
      'te lèves',
      'se lève',
      'nous levons',
      'vous levez',
      'se lèvent'
    ],
    VerbTense.pastParticiple: ['levé', 'levés', 'levée', 'levées'],
  },
  auxiliary: Auxiliary.etre,
  pronominal: true,
);

final _onlyPasseSimple = _verb('gésir', {
  VerbTense.passeSimple: ['gus', 'gus', 'gut', 'gûmes', 'gûtes', 'gurent'],
});

class _SequentialSelector implements VerbSelector {
  int calls = 0;

  @override
  Verb next(List<Verb> pool) => pool[calls++ % pool.length];
}

void main() {
  group('ConjugationQuestion', () {
    test('prompt prefixes the capitalised subject for person tenses', () {
      const question = ConjugationQuestion(
        verb: Verb(
            infinitive: 'parler', tier: VerbTier.essential, zipf: 5, forms: {}),
        tense: VerbTense.futur,
        slot: 3,
        number: 1,
      );
      expect(question.prompt, 'Nous _____ (futur)');
    });

    test('prompt names the agreement for the past participle', () {
      const question = ConjugationQuestion(
        verb: Verb(
            infinitive: 'parler', tier: VerbTier.essential, zipf: 5, forms: {}),
        tense: VerbTense.pastParticiple,
        slot: 3,
        number: 1,
      );
      expect(question.prompt, '_____ (participe passé, féminin pluriel)');
    });

    test('prompt names the person after the blank for the imperative', () {
      final question = ConjugationQuestion(
        verb: _parler,
        tense: VerbTense.imperatif,
        slot: 1,
        number: 1,
      );
      expect(question.prompt, '_____ (impératif, tu)');
      expect(question.answer, 'parle');
    });

    test('prompt elides je before a vowel', () {
      final question = ConjugationQuestion(
        verb: _parler,
        tense: VerbTense.passeCompose,
        slot: 0,
        number: 1,
      );
      expect(question.answer, 'ai parlé');
      expect(question.prompt, "J'_____ (passé composé)");
    });

    test('prompt fixes the gender for an agreeing passé composé', () {
      ConjugationQuestion question(Verb verb, int slot, Agreement agreement) =>
          ConjugationQuestion(
            verb: verb,
            tense: VerbTense.passeCompose,
            slot: slot,
            number: 1,
            agreement: agreement,
          );

      final elle = question(_partir, 2, Agreement.feminineSingular);
      expect(elle.prompt, 'Elle _____ (passé composé)');
      expect(elle.answer, 'est partie');

      final ils = question(_seLever, 5, Agreement.masculinePlural);
      expect(ils.prompt, 'Ils _____ (passé composé)');
      expect(ils.answer, 'se sont levés');

      final je = question(_partir, 0, Agreement.feminineSingular);
      expect(je.prompt, 'Je (f) _____ (passé composé)');
      expect(je.answer, 'suis partie');

      final vous = question(_partir, 4, Agreement.femininePlural);
      expect(vous.prompt, 'Vous (f pl) _____ (passé composé)');
      expect(vous.answer, 'êtes parties');
    });

    test('matches trims and ignores case but requires accents', () {
      final question = ConjugationQuestion(
        verb: _parler,
        tense: VerbTense.pastParticiple,
        slot: 0,
        number: 1,
      );
      expect(question.answer, 'parlé');
      expect(question.matches('parlé'), isTrue);
      expect(question.matches('  PARLÉ '), isTrue);
      expect(question.matches('parle'), isFalse);
      expect(question.matches(''), isFalse);
    });

    test('matches tolerates extra spaces and curly apostrophes', () {
      final question = ConjugationQuestion(
        verb: _seLever,
        tense: VerbTense.passeCompose,
        slot: 1,
        number: 1,
        agreement: Agreement.masculineSingular,
      );
      expect(question.answer, "t'es levé");
      expect(question.matches("t'es  levé"), isTrue);
      expect(question.matches('t’es levé'), isTrue);
      expect(question.matches("t'es levée"), isFalse);
    });
  });

  group('ConjugationQuiz', () {
    test('asks five questions per verb before moving on', () {
      final selector = _SequentialSelector();
      final quiz = ConjugationQuiz(
        verbs: [_parler, _finir],
        tenses: {VerbTense.present},
        selector: selector,
        random: Random(1),
      );

      final first = [for (var i = 0; i < 5; i++) quiz.next()];
      expect(first.map((q) => q.verb.infinitive), everyElement('parler'));
      expect(first.map((q) => q.number), [1, 2, 3, 4, 5]);
      expect(selector.calls, 1);

      final sixth = quiz.next();
      expect(sixth.verb.infinitive, 'finir');
      expect(sixth.number, 1);
      expect(selector.calls, 2);
    });

    test('only asks enabled tenses the verb actually has', () {
      final quiz = ConjugationQuiz(
        verbs: [_parler],
        tenses: {
          VerbTense.futur,
          VerbTense.pastParticiple,
          VerbTense.imparfait
        },
        random: Random(2),
      );

      for (var i = 0; i < 50; i++) {
        final q = quiz.next();
        expect(q.tense, isIn([VerbTense.futur, VerbTense.pastParticiple]));
        expect(q.answer, isNotEmpty);
      }
    });

    test('never lands on a NA imperative slot', () {
      final quiz = ConjugationQuiz(
        verbs: [_parler],
        tenses: {VerbTense.imperatif},
        random: Random(3),
      );

      for (var i = 0; i < 50; i++) {
        expect(quiz.next().slot, isIn([1, 3, 4]));
      }
    });

    test('sets an agreement only for agreeing passé composé questions', () {
      final quiz = ConjugationQuiz(
        verbs: [_parler, _partir, _seLever],
        tenses: {VerbTense.passeCompose, VerbTense.present},
        random: Random(5),
      );

      final seen = <Agreement>{};
      for (var i = 0; i < 90; i++) {
        final q = quiz.next();
        expect(q.answer, isNotEmpty);
        if (q.tense == VerbTense.passeCompose && q.verb.participleAgrees) {
          expect(q.agreement, isNotNull, reason: q.verb.infinitive);
          expect(q.agreement, isIn(Agreement.validFor(q.slot)));
          seen.add(q.agreement!);
        } else {
          expect(q.agreement, isNull, reason: q.verb.infinitive);
        }
      }
      expect(seen.length, greaterThan(1));
    });

    test('excludes verbs lacking every enabled tense', () {
      final quiz = ConjugationQuiz(
        verbs: [_parler, _onlyPasseSimple],
        tenses: {VerbTense.present},
        random: Random(4),
      );

      for (var i = 0; i < 50; i++) {
        expect(quiz.next().verb.infinitive, 'parler');
      }
    });

    test('is empty when no verb has an enabled tense', () {
      expect(
        ConjugationQuiz(verbs: [_parler], tenses: {}).isEmpty,
        isTrue,
      );
      expect(
        ConjugationQuiz(verbs: [_parler], tenses: {VerbTense.passeSimple})
            .isEmpty,
        isTrue,
      );
      expect(
        ConjugationQuiz(verbs: [_finir], tenses: {VerbTense.passeCompose})
            .isEmpty,
        isTrue,
      );
      expect(
        ConjugationQuiz(verbs: [], tenses: {VerbTense.present}).isEmpty,
        isTrue,
      );
      expect(
        ConjugationQuiz(verbs: [_parler], tenses: {VerbTense.present}).isEmpty,
        isFalse,
      );
    });
  });
}
