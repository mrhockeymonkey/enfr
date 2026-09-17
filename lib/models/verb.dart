import 'package:enfr/models/auxiliary.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';

class Verb {
  final String infinitive;
  final VerbTier tier;
  final double zipf;
  final Map<VerbTense, List<String?>> forms;

  /// Auxiliary used in compound tenses. Pronominal verbs always take `être`.
  final Auxiliary auxiliary;

  /// True for "se lever" style entries, whose stored forms already carry the
  /// reflexive pronoun ("me lève", "lève-toi").
  final bool pronominal;

  const Verb({
    required this.infinitive,
    required this.tier,
    required this.zipf,
    required this.forms,
    this.auxiliary = Auxiliary.avoir,
    this.pronominal = false,
  });

  static Verb? fromJson(
      String infinitive, VerbTier tier, Map<String, dynamic> json) {
    final forms = <VerbTense, List<String?>>{};
    for (final tense in VerbTense.values) {
      final code = tense.code;
      if (code == null) continue;
      final raw = json[code];
      if (raw is! List || raw.length != tense.slots.length) continue;
      final list = [
        for (final f in raw)
          if (f is String && f != 'NA' && f.isNotEmpty) f else null
      ];
      if (list.every((f) => f == null)) continue;
      forms[tense] = list;
    }
    if (forms.isEmpty) return null;
    final meta = json['meta'];
    final pronominal = meta is Map && meta['pronominal'] == true;
    return Verb(
      infinitive: infinitive,
      tier: tier,
      zipf: (json['zipf'] as num?)?.toDouble() ?? 0,
      forms: forms,
      auxiliary: pronominal
          ? Auxiliary.etre
          : Auxiliary.fromJson(meta is Map ? meta['auxiliary'] : null),
      pronominal: pronominal,
    );
  }

  /// Whether the past participle agrees with the subject in compound tenses
  /// (être-auxiliary and pronominal verbs).
  bool get participleAgrees => pronominal || auxiliary == Auxiliary.etre;

  bool hasTense(VerbTense tense) {
    if (tense.compound) {
      return forms.containsKey(VerbTense.present) &&
          forms.containsKey(VerbTense.pastParticiple);
    }
    return forms.containsKey(tense);
  }

  /// The form for [tense] and [slot], or null when it does not exist.
  ///
  /// For a compound tense the form is built from the auxiliary's present tense
  /// and the past participle. [agreement] picks the participle's gender and
  /// number when the verb agrees with its subject; it defaults to the
  /// conventional masculine form for the slot and is ignored for avoir verbs.
  String? form(VerbTense tense, int slot, {Agreement? agreement}) {
    if (!tense.compound) return forms[tense]?[slot];
    if (!hasTense(tense) || forms[VerbTense.present]![slot] == null) {
      return null;
    }
    final chosen = participleAgrees
        ? (agreement ?? Agreement.defaultFor(slot))
        : Agreement.masculineSingular;
    final participle = forms[VerbTense.pastParticiple]![chosen.participleSlot];
    if (participle == null) return null;
    final aux =
        pronominal ? pronominalAuxiliaryPresent[slot] : auxiliary.present[slot];
    return '$aux $participle';
  }

  List<int> slotsFor(VerbTense tense) {
    // A compound tense exists for exactly the persons the present tense has, so
    // impersonal verbs (falloir) only offer "il a fallu".
    if (tense.compound) {
      return hasTense(tense) ? slotsFor(VerbTense.present) : const [];
    }
    final list = forms[tense];
    if (list == null) return const [];
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] != null) i
    ];
  }
}
