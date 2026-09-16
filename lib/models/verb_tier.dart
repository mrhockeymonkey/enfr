enum VerbTier {
  essential('Essential', '46 most frequent verbs'),
  common('Common', '431 everyday verbs'),
  moderate('Moderate', '1,129 less frequent verbs'),
  uncommon('Uncommon', '2,503 infrequent verbs'),
  rare('Rare', '3,717 rare and literary verbs');

  const VerbTier(this.label, this.description);

  final String label;
  final String description;

  String get assetPath => 'assets/verbs/verbs_$name.json';
}
