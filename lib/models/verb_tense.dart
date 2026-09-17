const _persons = ['je', 'tu', 'il/elle', 'nous', 'vous', 'ils/elles'];

const _agreements = [
  'masculin singulier',
  'masculin pluriel',
  'féminin singulier',
  'féminin pluriel',
];

enum VerbTense {
  present('P', 'présent', _persons, subjectPrefix: true),
  // Compound: built in the app from the auxiliary's present tense and the past
  // participle, so it has no code in the JSON data.
  passeCompose(null, 'passé composé', _persons,
      subjectPrefix: true, compound: true),
  imparfait('I', 'imparfait', _persons, subjectPrefix: true),
  futur('F', 'futur', _persons, subjectPrefix: true),
  conditionnel('C', 'conditionnel', _persons, subjectPrefix: true),
  passeSimple('J', 'passé simple', _persons, subjectPrefix: true),
  subjonctifPresent('S', 'subjonctif présent', _persons, subjectPrefix: true),
  subjonctifImparfait('T', 'subjonctif imparfait', _persons,
      subjectPrefix: true),
  // The imperative has no subject ("lève-toi"), so the person is named after
  // the blank instead of in front of it.
  imperatif('Y', 'impératif', _persons, subjectPrefix: false),
  pastParticiple('K', 'participe passé', _agreements, subjectPrefix: false);

  const VerbTense(this.code, this.displayName, this.slots,
      {required this.subjectPrefix, this.compound = false});

  /// Key of this tense in the verb JSON, or null for a computed tense.
  final String? code;
  final String displayName;
  final List<String> slots;
  final bool subjectPrefix;

  /// True when the forms are built from an auxiliary and the past participle
  /// rather than read from the data.
  final bool compound;
}
