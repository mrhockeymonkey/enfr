import 'dart:math';

import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:enfr/services/verb_selector.dart';
import 'package:flutter_test/flutter_test.dart';

Verb _verb(String infinitive, Map<VerbTense, List<String?>> forms) => Verb(
      infinitive: infinitive,
      tier: VerbTier.essential,
      zipf: 5,
      forms: forms,
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
