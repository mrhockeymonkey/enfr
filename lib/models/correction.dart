enum CorrectionStatus { active, fixed }

class Correction {
  final String originalText;
  final String suggestedText;
  final CorrectionStatus status;

  const Correction({
    required this.originalText,
    required this.suggestedText,
    this.status = CorrectionStatus.active,
  });

  Correction copyWith({
    String? originalText,
    String? suggestedText,
    CorrectionStatus? status,
  }) =>
      Correction(
        originalText: originalText ?? this.originalText,
        suggestedText: suggestedText ?? this.suggestedText,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'suggestedText': suggestedText,
        'status': status.name,
      };

  factory Correction.fromJson(Map<String, dynamic> j) => Correction(
        originalText: j['originalText'] as String,
        suggestedText: j['suggestedText'] as String,
        status: _statusFromJson(j['status']),
      );

  static CorrectionStatus _statusFromJson(Object? raw) {
    if (raw is String) {
      for (final s in CorrectionStatus.values) {
        if (s.name == raw) return s;
      }
    }
    return CorrectionStatus.active;
  }
}

extension CorrectionListX on List<Correction> {
  List<Correction> get active =>
      where((c) => c.status == CorrectionStatus.active).toList();
  List<Correction> get fixed =>
      where((c) => c.status == CorrectionStatus.fixed).toList();
}
