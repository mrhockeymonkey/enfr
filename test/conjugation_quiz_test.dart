import 'dart:math';

import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

Verb _verb(
  String infinitive,
  Map<VerbTense, List<String?>> forms, {
  Auxiliary auxiliary = Auxiliary.avoir,
  bool pronominal = false,
  bool hAspire = false,
}) =>
    Verb(
      infinitive: infinitive,
      tier: VerbTier.essential,
      zipf: 5,
      forms: forms,
      auxiliary: auxiliary,
      pronominal: pronominal,
      hAspire: hAspire,
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
      expect(question.prompt, ('Nous ', ''));
    });

    test('prompt names the agreement for the past participle', () {
      const question = ConjugationQuestion(
        verb: Verb(
            infinitive: 'parler', tier: VerbTier.essential, zipf: 5, forms: {}),
        tense: VerbTense.pastParticiple,
        slot: 3,
        number: 1,
      );
      expect(question.prompt, ('', ' (féminin pluriel)'));
    });

    test('prompt names the person after the blank for the imperative', () {
      final question = ConjugationQuestion(
        verb: _parler,
        tense: VerbTense.imperatif,
        slot: 1,
        number: 1,
      );
      expect(question.prompt, ('', ' (tu)'));
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
      expect(question.prompt, ("J'", ''));
    });

    test('prompt elides je before a silent h but not an aspirated one', () {
      ConjugationQuestion je(Verb verb) => ConjugationQuestion(
          verb: verb, tense: VerbTense.present, slot: 0, number: 1);
      const persons = [null, null, null, null, null, null];

      final habiter = _verb('habiter', {
        VerbTense.present: ['habite', ...persons.skip(1)],
      });
      expect(je(habiter).prompt, ("J'", ''));

      final hair = _verb(
          'haïr',
          {
            VerbTense.present: ['hais', ...persons.skip(1)],
          },
          hAspire: true);
      expect(je(hair).prompt, ('Je ', ''));
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
      expect(elle.prompt, ('Elle ', ''));
      expect(elle.answer, 'est partie');

      final ils = question(_seLever, 5, Agreement.masculinePlural);
      expect(ils.prompt, ('Ils ', ''));
      expect(ils.answer, 'se sont levés');

      final je = question(_partir, 0, Agreement.feminineSingular);
      expect(je.prompt, ('Je ', ' (f)'));
      expect(je.answer, 'suis partie');

      final vous = question(_partir, 4, Agreement.femininePlural);
      expect(vous.prompt, ('Vous ', ' (f pl)'));
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
    test('asks one verb for a numbered session of 25 questions', () {
      final quiz = ConjugationQuiz(
        verb: _parler,
        tenses: {VerbTense.present},
        random: Random(1),
      );

      final questions = [
        for (var i = 0; i < ConjugationQuiz.questionsPerSession; i++)
          quiz.next()
      ];
      expect(questions.map((q) => q.verb.infinitive), everyElement('parler'));
      expect(questions.map((q) => q.number), [for (var i = 1; i <= 25; i++) i]);
      expect(quiz.isFinished, isTrue);
    });

    test('is not finished before the last question', () {
      final quiz = ConjugationQuiz(
        verb: _parler,
        tenses: {VerbTense.present},
        random: Random(1),
      );
      expect(quiz.isFinished, isFalse);
      for (var i = 0; i < ConjugationQuiz.questionsPerSession - 1; i++) {
        quiz.next();
      }
      expect(quiz.isFinished, isFalse);
    });

    test('only asks enabled tenses the verb actually has', () {
      final quiz = ConjugationQuiz(
        verb: _parler,
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
        verb: _parler,
        tenses: {VerbTense.imperatif},
        random: Random(3),
      );

      for (var i = 0; i < 50; i++) {
        expect(quiz.next().slot, isIn([1, 3, 4]));
      }
    });

    test('sets an agreement only for agreeing passé composé questions', () {
      final seen = <Agreement>{};
      for (final verb in [_parler, _partir, _seLever]) {
        final quiz = ConjugationQuiz(
          verb: verb,
          tenses: {VerbTense.passeCompose, VerbTense.present},
          random: Random(5),
        );
        for (var i = 0; i < 30; i++) {
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
      }
      expect(seen.length, greaterThan(1));
    });

    test('canQuiz needs at least one enabled tense the verb has', () {
      expect(ConjugationQuiz.canQuiz(_parler, {}), isFalse);
      expect(
          ConjugationQuiz.canQuiz(_parler, {VerbTense.passeSimple}), isFalse);
      expect(
          ConjugationQuiz.canQuiz(_finir, {VerbTense.passeCompose}), isFalse);
      expect(ConjugationQuiz.canQuiz(_onlyPasseSimple, {VerbTense.present}),
          isFalse);
      expect(ConjugationQuiz.canQuiz(_parler, {VerbTense.present}), isTrue);
    });
  });
}
