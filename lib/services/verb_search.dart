import 'package:enfr/models/verb.dart';

/// Verbs whose infinitive contains [query], ignoring case and accents.
///
/// Matches that start with the query (after any "se "/"s'" prefix) come
/// first, then the rest; each group is ordered most frequent first. An empty
/// query returns [verbs] unchanged.
List<Verb> searchVerbs(List<Verb> verbs, String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return verbs;
  final prefix = <Verb>[];
  final contains = <Verb>[];
  for (final verb in verbs) {
    final name = _fold(verb.infinitive);
    if (_stripReflexive(name).startsWith(q) || name.startsWith(q)) {
      prefix.add(verb);
    } else if (name.contains(q)) {
      contains.add(verb);
    }
  }
  int byZipf(Verb a, Verb b) => b.zipf.compareTo(a.zipf);
  return [...prefix..sort(byZipf), ...contains..sort(byZipf)];
}

String _stripReflexive(String name) {
  if (name.startsWith('se ')) return name.substring(3);
  if (name.startsWith("s'")) return name.substring(2);
  return name;
}

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', //
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ÿ': 'y', //
  '’': "'",
};

String _fold(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_accents[ch] ?? ch);
  }
  return out.toString();
}
