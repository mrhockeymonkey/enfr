import 'dart:math';

import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';

class ConjugationQuestion {
  final Verb verb;
  final VerbTense tense;
  final int slot;
  final int number;

  /// Gender and number the answer must agree with. Set only for a compound
  /// tense of a verb whose participle agrees with the subject; the prompt then
  /// names the gender ("Elle", "Ils", "Je _____ (f)") so exactly one form is
  /// right.
  final Agreement? agreement;

  const ConjugationQuestion({
    required this.verb,
    required this.tense,
    required this.slot,
    required this.number,
    this.agreement,
  });

  String get answer => verb.form(tense, slot, agreement: agreement)!;

  /// The text before and after the blank the answer fills. The tense is shown
  /// beside the sentence rather than in it, so only a person or agreement that
  /// has no subject slot ("tu" for the imperative, "féminin pluriel" for the
  /// participle) is bracketed after the blank, as is a gender the subject
  /// pronoun can't show ("Tu _____ (m)").
  (String, String) get prompt {
    final label = tense.slots[slot];
    if (!tense.subjectPrefix) return ('', ' ($label)');
    final agreement = this.agreement;
    final showsGender = slot == 2 || slot == 5;
    return (
      _subject(label),
      agreement == null || showsGender ? '' : ' (${agreement.label})',
    );
  }

  static const _vowels = 'aeiouàâäéèêëîïôöùûü';

  /// Whether je elides before the answer: it starts with a vowel, or with an
  /// h that is not aspirated ("j'habite", but "je hais").
  bool get _elides {
    final first = answer[0];
    return _vowels.contains(first) || (first == 'h' && !verb.hAspire);
  }

  /// The capitalised subject and the space (or elision) before the blank:
  /// "Nous ", "Elle ", or "J'" when [_elides]. With an [agreement], il/elle
  /// and ils/elles narrow to the pronoun of that gender.
  String _subject(String label) {
    final agreement = this.agreement;
    final subject = agreement == null
        ? label
        : switch (slot) {
            2 => agreement.feminine ? 'elle' : 'il',
            5 => agreement.feminine ? 'elles' : 'ils',
            _ => label,
          };
    if (slot == 0 && _elides) return "J'";
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
  static const questionsPerSession = 25;

  final Verb verb;
  final Set<VerbTense> _tenses;
  final Random _random;

  int _asked = 0;
  (VerbTense, int, Agreement?)? _last;

  ConjugationQuiz({
    required this.verb,
    required Set<VerbTense> tenses,
    Random? random,
  })  : _tenses = tenses,
        _random = random ?? Random();

  /// Whether [verb] has at least one form in any of [tenses].
  static bool canQuiz(Verb verb, Set<VerbTense> tenses) =>
      tenses.any((t) => verb.slotsFor(t).isNotEmpty);

  bool get isFinished => _asked >= questionsPerSession;

  ConjugationQuestion next() {
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
