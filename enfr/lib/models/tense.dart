class Tense {
  const Tense({
    required this.je,
    required this.tu,
    required this.il,
    required this.nous,
    required this.vous,
    required this.ils,
  });

  final String? je;
  final String? tu;
  final String? il;
  final String? nous;
  final String? vous;
  final String? ils;

  static Tense? fromStr(String? str) {
    if (str == null) return null;
    List<String> parts = str.split('|');

    return Tense(
      je: parts.elementAtOrNull(0),
      tu: parts.elementAtOrNull(1),
      il: parts.elementAtOrNull(2),
      nous: parts.elementAtOrNull(3),
      vous: parts.elementAtOrNull(4),
      ils: parts.elementAtOrNull(5),
    );
  }
}
