import 'package:enfr/models/correction.dart';

final RegExp _itemRegExp = RegExp(
  r'<text>(.*?)</text>\s*<correction>(.*?)</correction>(?:\s*<status>(.*?)</status>)?',
  dotAll: true,
);

List<Correction> parseCorrections(String raw) {
  return _itemRegExp.allMatches(raw).map((m) {
    return Correction(
      originalText: m.group(1)!.trim(),
      suggestedText: m.group(2)!.trim(),
      status: _parseStatus(m.group(3)),
    );
  }).toList();
}

CorrectionStatus _parseStatus(String? raw) {
  if (raw == null) return CorrectionStatus.active;
  final v = raw.trim().toLowerCase();
  return v == 'fixed' ? CorrectionStatus.fixed : CorrectionStatus.active;
}
