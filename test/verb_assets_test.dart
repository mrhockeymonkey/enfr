import 'dart:convert';
import 'dart:io';

import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the bundled tier files, read from disk: every entry loads through
/// [Verb.fromJson], pronominal entries are well formed and link to their base
/// verb within the same file, and the metadata the app relies on is present.
void main() {
  final pronounPrefix = RegExp(r"^(me |m'|te |t'|se |s'|nous |vous )");

  // infinitive -> (entry, tier), across all tiers
  late Map<String, (Map<String, dynamic>, VerbTier)> all;
  late Map<VerbTier, Map<String, dynamic>> files;

  setUpAll(() {
    files = {
      for (final tier in VerbTier.values)
        tier: jsonDecode(File(tier.assetPath).readAsStringSync())
            as Map<String, dynamic>,
    };
    all = {
      for (final MapEntry(key: tier, value: json) in files.entries)
        for (final entry in (json['verbs'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as Map<String, dynamic>, tier),
    };
  });

  Map<String, dynamic> meta(String key) => all[key]!.$1['meta'];

  group('bundled verb tiers', () {
    for (final tier in VerbTier.values) {
      test('${tier.name} loads every entry', () {
        final json = files[tier]!;
        final entries = json['verbs'] as Map<String, dynamic>;
        expect(json['tier'], tier.name);
        expect(entries.length, json['verb_count']);
        expect(entries, isNotEmpty);

        for (final entry in entries.entries) {
          final verb = Verb.fromJson(
              entry.key, tier, entry.value as Map<String, dynamic>);
          expect(verb, isNotNull, reason: entry.key);
          expect(
            VerbTense.values.any((t) => verb!.slotsFor(t).isNotEmpty),
            isTrue,
            reason: entry.key,
          );
        }
      });

      test('${tier.name} links base and pronominal entries within the file',
          () {
        final entries = files[tier]!['verbs'] as Map<String, dynamic>;
        for (final entry in entries.entries) {
          final meta = (entry.value as Map<String, dynamic>)['meta']
              as Map<String, dynamic>;
          if (meta['pronominal'] == true) {
            expect(meta['auxiliary'], 'être', reason: entry.key);
            final base = meta['base'] as String?;
            if (base == null) {
              expect(meta['pronominal_kind'], 'essential', reason: entry.key);
            } else {
              expect(entries.containsKey(base), isTrue,
                  reason: '${entry.key} -> $base');
              final baseMeta = (entries[base] as Map<String, dynamic>)['meta']
                  as Map<String, dynamic>;
              expect(baseMeta['pronominal_form'], entry.key);
            }
          } else {
            expect(meta['auxiliary'], isIn(['avoir', 'être']),
                reason: entry.key);
            final pron = meta['pronominal_form'] as String?;
            if (pron != null) {
              expect(entries.containsKey(pron), isTrue,
                  reason: '${entry.key} -> $pron');
            }
          }
        }
      });
    }

    test('pronominal entries carry the reflexive pronoun', () {
      for (final MapEntry(key: key, value: (entry, _)) in all.entries) {
        final meta = entry['meta'] as Map<String, dynamic>;
        if (meta['pronominal'] != true) continue;
        expect(key, startsWith(meta['elides'] == true ? "s'" : 'se '));
        for (final f in (entry['P'] as List?) ?? const []) {
          if (f == 'NA') continue;
          expect(pronounPrefix.hasMatch(f as String), isTrue,
              reason: '$key: $f');
        }
        for (final f in (entry['Y'] as List?) ?? const []) {
          if (f == 'NA') continue;
          expect(f, matches(RegExp(r'-(toi|nous|vous)$')), reason: '$key: $f');
        }
      }
    });

    test('well-known verbs are classified as expected', () {
      expect(meta('se lever')['pronominal_kind'], 'lexicalised');
      expect(meta('se lever')['base'], 'lever');
      expect(all['se lever']!.$2, all['lever']!.$2);
      expect(meta('se laver')['pronominal_kind'], 'reflexive');
      expect(meta("s'évanouir")['pronominal_kind'], 'essential');
      expect(all.containsKey('évanouir'), isFalse);
      expect(meta('se souvenir')['prepositions'], contains('de'));
      expect(meta('se hâter')['elides'], isFalse);
      expect(meta("s'habiller")['elides'], isTrue);
      expect(meta("s'agir")['impersonal_only'], isTrue);
      expect(meta('se bagarrer')['pronoun_optional'], isTrue);
      expect(all["s'évanouir"]!.$1['P'], contains("m'évanouis"));
      expect(all['se lever']!.$1['Y'], contains('lève-toi'));
    });

    test('auxiliaries follow the curated être list', () {
      for (final key in ['aller', 'partir', 'venir', 'naître', 'sortir']) {
        expect(meta(key)['auxiliary'], 'être', reason: key);
      }
      for (final key in ['parler', 'avoir', 'être', 'finir', 'courir']) {
        expect(meta(key)['auxiliary'], 'avoir', reason: key);
      }
      final partir =
          Verb.fromJson('partir', VerbTier.common, all['partir']!.$1)!;
      expect(partir.auxiliary, Auxiliary.etre);
      expect(partir.form(VerbTense.passeCompose, 0), 'suis parti');
      final seLever =
          Verb.fromJson('se lever', VerbTier.common, all['se lever']!.$1)!;
      expect(
          seLever.form(VerbTense.passeCompose, 2,
              agreement: Agreement.feminineSingular),
          "s'est levée");
    });

    test('defective verbs are excluded by design', () {
      for (final key in ['accroire', 'quérir', 'ravoir', 'parfaire']) {
        expect(all.containsKey(key), isFalse, reason: key);
      }
    });
  });
}
