import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';

class VerbQuizSettings {
  static const defaultTiers = {VerbTier.essential};
  static const defaultTenses = {
    VerbTense.present,
    VerbTense.passeCompose,
    VerbTense.imparfait,
    VerbTense.futur,
    VerbTense.pastParticiple,
  };
  static const defaults = VerbQuizSettings(
    tiers: defaultTiers,
    tenses: defaultTenses,
  );

  final Set<VerbTier> tiers;
  final Set<VerbTense> tenses;

  const VerbQuizSettings({required this.tiers, required this.tenses});

  VerbQuizSettings copyWith({Set<VerbTier>? tiers, Set<VerbTense>? tenses}) =>
      VerbQuizSettings(
        tiers: tiers ?? this.tiers,
        tenses: tenses ?? this.tenses,
      );

  Map<String, dynamic> toJson() => {
        'tiers': tiers.map((t) => t.name).toList(),
        'tenses': tenses.map((t) => t.name).toList(),
      };

  factory VerbQuizSettings.fromJson(Map<String, dynamic> json) {
    final tiers = _parseNames(json['tiers'], VerbTier.values);
    final tenses = _parseNames(json['tenses'], VerbTense.values);
    return VerbQuizSettings(
      tiers: tiers.isEmpty ? defaultTiers : tiers,
      tenses: tenses.isEmpty ? defaultTenses : tenses,
    );
  }

  static Set<T> _parseNames<T extends Enum>(dynamic raw, List<T> values) {
    if (raw is! List) return {};
    final byName = {for (final v in values) v.name: v};
    return {
      for (final name in raw)
        if (byName[name] != null) byName[name]!
    };
  }
}
