import 'dart:convert';
import 'dart:io';

import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bundled verb tiers', () {
    for (final tier in VerbTier.values) {
      test('${tier.name} parses without errors', () {
        final raw = File(tier.assetPath).readAsStringSync();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final entries = json['verbs'] as Map<String, dynamic>;

        final verbs = <Verb>[];
        for (final entry in entries.entries) {
          final verb = Verb.fromJson(
              entry.key, tier, entry.value as Map<String, dynamic>);
          if (verb != null) verbs.add(verb);
        }

        expect(verbs, isNotEmpty);
        expect(verbs.length, lessThanOrEqualTo(json['verb_count'] as int));
        for (final verb in verbs) {
          expect(
            VerbTense.values.any((t) => verb.slotsFor(t).isNotEmpty),
            isTrue,
            reason: verb.infinitive,
          );
        }
      });
    }
  });
}
