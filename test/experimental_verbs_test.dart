import 'dart:convert';
import 'dart:io';

import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the experimental Lefff-derived list, which is not bundled in the
/// app yet but must stay loadable by [Verb.fromJson] and internally consistent.
void main() {
  const path = 'assets/verbs/experimental/verbs_lefff.json';
  final pronounPrefix = RegExp(r"^(me |m'|te |t'|se |s'|nous |vous )");

  late Map<String, dynamic> json;
  late Map<String, dynamic> entries;

  setUpAll(() {
    json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    entries = json['verbs'] as Map<String, dynamic>;
  });

  test('every entry loads through Verb.fromJson', () {
    expect(entries.length, json['verb_count']);
    for (final entry in entries.entries) {
      final verb = Verb.fromJson(
          entry.key, VerbTier.rare, entry.value as Map<String, dynamic>);
      expect(verb, isNotNull, reason: entry.key);
      expect(
        VerbTense.values.any((t) => verb!.slotsFor(t).isNotEmpty),
        isTrue,
        reason: entry.key,
      );
    }
  });

  test('base and pronominal links resolve within the file', () {
    for (final entry in entries.entries) {
      final meta =
          (entry.value as Map<String, dynamic>)['meta'] as Map<String, dynamic>;
      if (meta['pronominal'] == true) {
        final base = meta['base'] as String?;
        if (base != null) {
          expect(entries.containsKey(base), isTrue,
              reason: '${entry.key} -> $base');
          final baseMeta = (entries[base] as Map<String, dynamic>)['meta']
              as Map<String, dynamic>;
          expect(baseMeta['pronominal_form'], entry.key);
        } else {
          expect(meta['pronominal_kind'], 'essential', reason: entry.key);
        }
      } else {
        final pron = meta['pronominal_form'] as String?;
        if (pron != null) {
          expect(entries.containsKey(pron), isTrue,
              reason: '${entry.key} -> $pron');
        }
      }
    }
  });

  test('pronominal entries carry the reflexive pronoun', () {
    for (final entry in entries.entries) {
      final value = entry.value as Map<String, dynamic>;
      final meta = value['meta'] as Map<String, dynamic>;
      if (meta['pronominal'] != true) continue;
      expect(entry.key, startsWith(meta['elides'] == true ? "s'" : 'se '));
      for (final f in (value['P'] as List?) ?? const []) {
        if (f == 'NA') continue;
        expect(pronounPrefix.hasMatch(f as String), isTrue,
            reason: '${entry.key}: $f');
      }
      for (final f in (value['Y'] as List?) ?? const []) {
        if (f == 'NA') continue;
        expect(f, matches(RegExp(r'-(toi|nous|vous)$')),
            reason: '${entry.key}: $f');
      }
    }
  });

  test('well-known verbs are classified as expected', () {
    Map<String, dynamic> meta(String key) =>
        (entries[key] as Map<String, dynamic>)['meta'] as Map<String, dynamic>;

    expect(meta('se lever')['pronominal_kind'], 'lexicalised');
    expect(meta('se lever')['base'], 'lever');
    expect(meta('se laver')['pronominal_kind'], 'reflexive');
    expect(meta("s'évanouir")['pronominal_kind'], 'essential');
    expect(entries.containsKey('évanouir'), isFalse);
    expect(meta('se souvenir')['prepositions'], contains('de'));
    expect(meta('se hâter')['elides'], isFalse);
    expect(meta("s'habiller")['elides'], isTrue);
    expect(meta("s'agir")['impersonal_only'], isTrue);
    expect(meta('se bagarrer')['pronoun_optional'], isTrue);
    expect((entries["s'évanouir"] as Map<String, dynamic>)['P'],
        contains("m'évanouis"));
    expect((entries['se lever'] as Map<String, dynamic>)['Y'],
        contains('lève-toi'));
  });
}
