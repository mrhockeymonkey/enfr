enum VerbTier {
  essential('Essential', '78 most frequent verbs'),
  common('Common', '789 everyday verbs'),
  moderate('Moderate', '1,936 less frequent verbs'),
  uncommon('Uncommon', '3,734 infrequent verbs'),
  rare('Rare', '4,786 rare and literary verbs');

  const VerbTier(this.label, this.description);

  final String label;
  final String description;

  String get assetPath => 'assets/verbs/verbs_$name.json';
}
