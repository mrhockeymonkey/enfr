import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:enfr/services/verb_search.dart';
import 'package:flutter_test/flutter_test.dart';

Verb _verb(String infinitive, double zipf) => Verb(
      infinitive: infinitive,
      tier: VerbTier.essential,
      zipf: zipf,
      forms: const {},
    );

final _etre = _verb('être', 7);
final _lever = _verb('lever', 4);
final _seLever = _verb('se lever', 4.5);
final _elever = _verb('élever', 3.5);
final _relever = _verb('relever', 3.8);
final _sAppeler = _verb("s'appeler", 4.2);
final _verbs = [_etre, _lever, _seLever, _elever, _relever, _sAppeler];

List<String> _names(List<Verb> verbs) => [for (final v in verbs) v.infinitive];

void main() {
  test('empty query returns every verb in order', () {
    expect(searchVerbs(_verbs, ''), _verbs);
    expect(searchVerbs(_verbs, '  '), _verbs);
  });

  test('ignores accents and case', () {
    expect(_names(searchVerbs(_verbs, 'ETRE')), ['être']);
    expect(_names(searchVerbs(_verbs, 'ÉLEV')), ['élever', 'relever']);
  });

  test('prefix matches, including pronominal ones, come before contains', () {
    expect(
      _names(searchVerbs(_verbs, 'lever')),
      ['se lever', 'lever', 'relever', 'élever'],
    );
  });

  test("matches past an s' prefix", () {
    expect(_names(searchVerbs(_verbs, 'appel')), ["s'appeler"]);
  });

  test('returns nothing when no infinitive matches', () {
    expect(searchVerbs(_verbs, 'xyz'), isEmpty);
  });
}
