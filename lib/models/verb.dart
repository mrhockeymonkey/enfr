import 'package:enfr/models/tense.dart';
import 'package:yaml/yaml.dart';

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

  factory Verb.fromYaml(YamlMap map) {
    var i = map['inf'] as String;
    var m = map['eng'] as String;
    var present = map['pre'] as String?;
    var futur = map['fut'] as String?;
    var passeCompose = map['pas'] as String?;
    var imparfait = map['imp'] as String?;

    return Verb(
      infinitive: i,
      meaning: m,
      present: Tense.fromStr(present),
      futur: Tense.fromStr(futur),
      passeCompose: Tense.fromStr(passeCompose),
      imparfait: Tense.fromStr(imparfait),
    );
  }
}
