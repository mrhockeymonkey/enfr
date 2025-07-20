import 'package:enfr/models/tense.dart';
import 'package:enfr/models/tense_name.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/pages/verbs/widgets/conjugation_view.dart';
import 'package:enfr/pages/verbs/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class VerbsPage extends StatefulWidget {
  const VerbsPage({super.key});

  static const List<Verb> verbs = [
    Verb(
      infinitive: "Être",
      meaning: "to be",
      present: Tense(
        je: "je `suis`",
        tu: "tu `es`",
        il: "il / elle `est`",
        nous: "nous `sommes`",
        vous: "vous `êtes`",
        ils: "ils / elles `sont`",
      ),
      futur: Tense(
        je: 'je `serai`',
        tu: 'tu `seras`',
        il: 'il / elle `sera`',
        nous: 'nous `serons`',
        vous: 'vous `serez`',
        ils: 'ils / elles `seront`',
      ),
      passeCompose: Tense(
        je: "j'ai `été`",
        tu: "tu as `été`",
        il: "il / elle a `été`",
        nous: "nous avons `été`",
        vous: "vous avez  `été`",
        ils: "ils / elles ont `été`",
      ),
      imparfait: Tense(
        je: "j'`étais`",
        tu: "tu `étais`",
        il: "il / elle `était`",
        nous: "nous `étions`",
        vous: "vous `étiez`",
        ils: "ils / elles `étaient`",
      ),
    ),
    Verb(
      infinitive: "Avoir",
      meaning: "to have",
      present: Tense(
        je: "j'`ai`",
        tu: "tu `as`",
        il: "il / elle `a`",
        nous: "nous `avons`",
        vous: "vous `avez`",
        ils: "ils / elles `ont`",
      ),
    ),
  ];

  @override
  State<StatefulWidget> createState() => VerbsPageState();
}

class VerbsPageState extends State<VerbsPage> {
  late Verb currentVerb;

  @override
  void initState() {
    super.initState();
    currentVerb = VerbsPage.verbs.first;
  }

  void shuffle() {
    setState(() {
      currentVerb = VerbsPage.verbs[Random().nextInt(VerbsPage.verbs.length)];
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text("Verbs"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: shuffle,
        child: Icon(
          Icons.shuffle,
          color: Colors.black,
        ),
      ),
      body: Container(
          width: double.infinity,
          height: double.infinity,
          margin: EdgeInsets.all(8.0),
          child: Card(
              child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                Text(
                  currentVerb.infinitive,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                  ),
                ),
                Text(currentVerb.meaning),
                ConjugationView(
                  name: TenseName.present.displayName,
                  tense: currentVerb.present,
                ),
                ConjugationView(
                  name: TenseName.futur.displayName,
                  tense: currentVerb.futur,
                ),
                ConjugationView(
                  name: TenseName.passeCompose.displayName,
                  tense: currentVerb.passeCompose,
                ),
                ConjugationView(
                  name: TenseName.imparfait.displayName,
                  tense: currentVerb.imparfait,
                ),
              ],
            ),
          ))));
}
