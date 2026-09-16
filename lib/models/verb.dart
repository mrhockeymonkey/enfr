import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';

class Verb {
  final String infinitive;
  final VerbTier tier;
  final double zipf;
  final Map<VerbTense, List<String?>> forms;

  const Verb({
    required this.infinitive,
    required this.tier,
    required this.zipf,
    required this.forms,
  });

  static Verb? fromJson(
      String infinitive, VerbTier tier, Map<String, dynamic> json) {
    final forms = <VerbTense, List<String?>>{};
    for (final tense in VerbTense.values) {
      final raw = json[tense.code];
      if (raw is! List || raw.length != tense.slots.length) continue;
      forms[tense] = raw.map((f) => f == 'NA' ? null : f as String).toList();
    }
    if (forms.isEmpty) return null;
    return Verb(
      infinitive: infinitive,
      tier: tier,
      zipf: (json['zipf'] as num?)?.toDouble() ?? 0,
      forms: forms,
    );
  }

  bool hasTense(VerbTense tense) => forms.containsKey(tense);

  String? form(VerbTense tense, int slot) => forms[tense]?[slot];

  List<int> slotsFor(VerbTense tense) {
    final list = forms[tense];
    if (list == null) return const [];
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] != null) i
    ];
  }
}
