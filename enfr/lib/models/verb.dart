import 'package:enfr/models/tense.dart';

class Verb {
  const Verb({
    required this.infinitive,
    required this.meaning,
    this.present,
    this.futur,
    this.passeCompose,
    this.imparfait,
  });

  final String infinitive;
  final String meaning;
  final Tense? present;
  final Tense? futur;
  final Tense? passeCompose;
  final Tense? imparfait;
}
