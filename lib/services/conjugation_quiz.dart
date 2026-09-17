import 'dart:math';

import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/services/verb_selector.dart';

class ConjugationQuestion {
  final Verb verb;
  final VerbTense tense;
  final int slot;
  final int number;

  /// Gender and number the answer must agree with. Set only for a compound
  /// tense of a verb whose participle agrees with the subject; the prompt then
  /// names the gender ("Elle", "Ils", "Je (f)") so exactly one form is right.
  final Agreement? agreement;

  const ConjugationQuestion({
    required this.verb,
    required this.tense,
    required this.slot,
    required this.number,
    this.agreement,
  });

  String get answer => verb.form(tense, slot, agreement: agreement)!;

  String get prompt {
    final label = tense.slots[slot];
    if (!tense.subjectPrefix) {
      return '_____ (${tense.displayName}, $label)';
    }
    return '${_subject(label)}_____ (${tense.displayName})';
  }

  static const _vowels = 'aeiouàâäéèêëîïôöùûü';

  /// The capitalised subject and the space (or elision) before the blank:
  /// "Nous ", "Elle ", "Je (f) ", or "J'" when the answer starts with a vowel.
  String _subject(String label) {
    final agreement = this.agreement;
    final subject = agreement == null
        ? label
        : switch (slot) {
            2 => agreement.feminine ? 'elle' : 'il',
            5 => agreement.feminine ? 'elles' : 'ils',
            _ => '$label (${agreement.label})',
          };
    if (slot == 0 && _vowels.contains(answer[0])) return "J'";
    return '${subject[0].toUpperCase()}${subject.substring(1)} ';
  }

  bool matches(String input) => _normalise(input) == _normalise(answer);

  static String _normalise(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'\s+'), ' ');
}

class ConjugationQuiz {
  static const questionsPerVerb = 5;

  final List<Verb> _pool;
  final Set<VerbTense> _tenses;
  final VerbSelector _selector;
  final Random _random;

  Verb? _currentVerb;
  int _asked = 0;
  (VerbTense, int, Agreement?)? _last;

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
    (VerbTense, int, Agreement?) pick;
    // Avoid asking the exact same form twice in a row when there is a choice.
    do {
      final tense = tenses[_random.nextInt(tenses.length)];
      final slots = verb.slotsFor(tense);
      final slot = slots[_random.nextInt(slots.length)];
      Agreement? agreement;
      if (tense.compound && verb.participleAgrees) {
        final options = Agreement.validFor(slot);
        agreement = options[_random.nextInt(options.length)];
      }
      pick = (tense, slot, agreement);
    } while (choices > 1 && pick == _last);
    _last = pick;
    final (tense, slot, agreement) = pick;
    _asked++;
    return ConjugationQuestion(
      verb: verb,
      tense: tense,
      slot: slot,
      number: _asked,
      agreement: agreement,
    );
  }
}
