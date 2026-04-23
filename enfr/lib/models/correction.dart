class Correction {
  final String originalText;
  final String suggestedText;

  const Correction({
    required this.originalText,
    required this.suggestedText,
  });

  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'suggestedText': suggestedText,
      };

  factory Correction.fromJson(Map<String, dynamic> j) => Correction(
        originalText: j['originalText'] as String,
        suggestedText: j['suggestedText'] as String,
      );
}
