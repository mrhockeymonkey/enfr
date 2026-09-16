import 'package:enfr/models/verb_quiz_settings.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerbQuizSettings', () {
    test('defaults to essential verbs and the core tenses', () {
      expect(VerbQuizSettings.defaults.tiers, {VerbTier.essential});
      expect(VerbQuizSettings.defaults.tenses, {
        VerbTense.present,
        VerbTense.imparfait,
        VerbTense.futur,
        VerbTense.pastParticiple,
      });
    });

    test('round-trips through JSON', () {
      const settings = VerbQuizSettings(
        tiers: {VerbTier.common, VerbTier.rare},
        tenses: {VerbTense.conditionnel, VerbTense.imperatif},
      );

      final restored = VerbQuizSettings.fromJson(settings.toJson());

      expect(restored.tiers, settings.tiers);
      expect(restored.tenses, settings.tenses);
    });

    test('ignores unknown enum names', () {
      final settings = VerbQuizSettings.fromJson({
        'tiers': ['common', 'legendary'],
        'tenses': ['futur', 'plusQueParfait'],
      });

      expect(settings.tiers, {VerbTier.common});
      expect(settings.tenses, {VerbTense.futur});
    });

    test('falls back to defaults for empty or missing sets', () {
      final empty = VerbQuizSettings.fromJson({'tiers': [], 'tenses': []});
      expect(empty.tiers, VerbQuizSettings.defaultTiers);
      expect(empty.tenses, VerbQuizSettings.defaultTenses);

      final missing = VerbQuizSettings.fromJson({});
      expect(missing.tiers, VerbQuizSettings.defaultTiers);
      expect(missing.tenses, VerbQuizSettings.defaultTenses);

      final garbage = VerbQuizSettings.fromJson({'tiers': 'essential'});
      expect(garbage.tiers, VerbQuizSettings.defaultTiers);
    });

    test('copyWith replaces only the given field', () {
      final copy = VerbQuizSettings.defaults.copyWith(tiers: {VerbTier.rare});
      expect(copy.tiers, {VerbTier.rare});
      expect(copy.tenses, VerbQuizSettings.defaultTenses);
    });
  });
}
