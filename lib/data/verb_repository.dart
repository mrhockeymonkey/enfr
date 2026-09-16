import 'dart:convert';

import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter/services.dart';

class VerbRepository {
  static final _cache = <VerbTier, List<Verb>>{};

  static Future<List<Verb>> loadTiers(Set<VerbTier> tiers) async {
    final verbs = <Verb>[];
    for (final tier in VerbTier.values) {
      if (!tiers.contains(tier)) continue;
      verbs.addAll(_cache[tier] ??= await _loadTier(tier));
    }
    return verbs;
  }

  static Future<List<Verb>> _loadTier(VerbTier tier) async {
    final raw = await rootBundle.loadString(tier.assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final entries = json['verbs'] as Map<String, dynamic>;
    return [
      for (final entry in entries.entries)
        if (Verb.fromJson(entry.key, tier, entry.value as Map<String, dynamic>)
            case final verb?)
          verb
    ];
  }
}
