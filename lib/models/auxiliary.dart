/// Auxiliary verb used to build compound tenses (passé composé, ...).
///
/// The present-tense forms are hard-coded here so a compound form can be built
/// for any verb without loading the `avoir` / `être` entries themselves, which
/// live in the essential tier and may not be enabled.
enum Auxiliary {
  avoir(['ai', 'as', 'a', 'avons', 'avez', 'ont']),
  etre(['suis', 'es', 'est', 'sommes', 'êtes', 'sont']);

  const Auxiliary(this.present);

  /// Present-tense forms indexed je, tu, il/elle, nous, vous, ils/elles.
  final List<String> present;

  /// Parses the `meta.auxiliary` value of a verb entry (`"avoir"` / `"être"`).
  static Auxiliary fromJson(Object? value) =>
      value == 'être' ? Auxiliary.etre : Auxiliary.avoir;
}

/// Reflexive pronoun plus `être`, for pronominal verbs ("je me suis levé").
/// The pronoun elides before `es` / `est`.
const pronominalAuxiliaryPresent = [
  'me suis',
  "t'es",
  "s'est",
  'nous sommes',
  'vous êtes',
  'se sont',
];

/// Gender and number agreement of a past participle, in the order the `K`
/// forms are stored: masculine singular, masculine plural, feminine singular,
/// feminine plural.
enum Agreement {
  masculineSingular(0, 'm'),
  masculinePlural(1, 'm pl'),
  feminineSingular(2, 'f'),
  femininePlural(3, 'f pl');

  const Agreement(this.participleSlot, this.label);

  /// Index into the past participle (`K`) forms.
  final int participleSlot;

  /// Short marker shown in a quiz prompt: "Je (f) _____".
  final String label;

  bool get feminine =>
      this == Agreement.feminineSingular || this == Agreement.femininePlural;

  /// Agreements a subject slot (je, tu, il/elle, nous, vous, ils/elles) allows.
  /// `vous` can be singular or plural, so it allows all four.
  static List<Agreement> validFor(int slot) => switch (slot) {
        0 || 1 || 2 => const [
            Agreement.masculineSingular,
            Agreement.feminineSingular
          ],
        3 || 5 => const [Agreement.masculinePlural, Agreement.femininePlural],
        _ => values,
      };

  /// Conventional reference-table agreement for a subject slot: masculine,
  /// singular for je/tu/il and plural for nous/vous/ils.
  static Agreement defaultFor(int slot) =>
      slot < 3 ? Agreement.masculineSingular : Agreement.masculinePlural;
}
