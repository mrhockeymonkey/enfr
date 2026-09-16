import 'dart:math';

import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/services/verb_selector.dart';

class ConjugationQuestion {
  final Verb verb;
  final VerbTense tense;
  final int slot;
  final int number;

  const ConjugationQuestion({
    required this.verb,
    required this.tense,
    required this.slot,
    required this.number,
  });

  String get answer => verb.form(tense, slot)!;

  String get prompt {
    final label = tense.slots[slot];
    if (tense.subjectPrefix) {
      final subject = label[0].toUpperCase() + label.substring(1);
      return '$subject _____ (${tense.displayName})';
    }
    return '_____ (${tense.displayName}, $label)';
  }

  bool matches(String input) =>
      input.trim().toLowerCase() == answer.toLowerCase();
}

class ConjugationQuiz {
  static const questionsPerVerb = 5;

  final List<Verb> _pool;
  final Set<VerbTense> _tenses;
  final VerbSelector _selector;
  final Random _random;

  Verb? _currentVerb;
  int _asked = 0;
  (VerbTense, int)? _last;

  ConjugationQuiz({
    required List<Verb> verbs,
    required Set<VerbTense> tenses,
    VerbSelector? selector,
    Random? random,
  })  : _tenses = tenses,
        _pool = verbs
            .where((v) => tenses.any((t) => v.slotsFor(t).isNotEmpty))
            .toList(),
        _selector = selector ?? RandomVerbSelector(random),
        _random = random ?? Random();

  bool get isEmpty => _pool.isEmpty;

  ConjugationQuestion next() {
    if (_currentVerb == null || _asked >= questionsPerVerb) {
      _currentVerb = _selector.next(_pool);
      _asked = 0;
    }
    final verb = _currentVerb!;
    final tenses = _tenses.where((t) => verb.slotsFor(t).isNotEmpty).toList();
    final choices = tenses.fold(0, (n, t) => n + verb.slotsFor(t).length);
    (VerbTense, int) pick;
    // Avoid asking the exact same form twice in a row when there is a choice.
    do {
      final tense = tenses[_random.nextInt(tenses.length)];
      final slots = verb.slotsFor(tense);
      pick = (tense, slots[_random.nextInt(slots.length)]);
    } while (choices > 1 && pick == _last);
    _last = pick;
    final (tense, slot) = pick;
    _asked++;
    return ConjugationQuestion(
      verb: verb,
      tense: tense,
      slot: slot,
      number: _asked,
    );
  }
}
