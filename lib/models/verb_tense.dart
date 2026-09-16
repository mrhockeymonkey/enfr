const _persons = ['je', 'tu', 'il/elle', 'nous', 'vous', 'ils/elles'];

const _agreements = [
  'masculin singulier',
  'masculin pluriel',
  'féminin singulier',
  'féminin pluriel',
];

enum VerbTense {
  present('P', 'présent', _persons, subjectPrefix: true),
  imparfait('I', 'imparfait', _persons, subjectPrefix: true),
  futur('F', 'futur', _persons, subjectPrefix: true),
  conditionnel('C', 'conditionnel', _persons, subjectPrefix: true),
  passeSimple('J', 'passé simple', _persons, subjectPrefix: true),
  subjonctifPresent('S', 'subjonctif présent', _persons, subjectPrefix: true),
  subjonctifImparfait('T', 'subjonctif imparfait', _persons,
      subjectPrefix: true),
  imperatif('Y', 'impératif', _persons, subjectPrefix: true),
  pastParticiple('K', 'participe passé', _agreements, subjectPrefix: false);

  const VerbTense(this.code, this.displayName, this.slots,
      {required this.subjectPrefix});

  final String code;
  final String displayName;
  final List<String> slots;
  final bool subjectPrefix;
}
