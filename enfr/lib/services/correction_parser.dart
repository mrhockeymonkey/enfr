import 'package:enfr/models/correction.dart';

final RegExp _pairRegExp = RegExp(
  r'<text>(.*?)</text>\s*<correction>(.*?)</correction>',
  dotAll: true,
);

List<Correction> parseCorrections(String raw) {
  return _pairRegExp.allMatches(raw).map((m) {
    return Correction(
      originalText: m.group(1)!.trim(),
      suggestedText: m.group(2)!.trim(),
    );
  }).toList();
}
