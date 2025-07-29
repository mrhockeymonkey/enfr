import 'package:enfr/data/verb-provider.dart';
import 'package:enfr/models/tense.dart';
import 'package:enfr/models/tense_name.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/pages/verbs/widgets/conjugation_view.dart';
import 'package:enfr/pages/verbs/widgets/highlighted_text.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class VerbsPage extends StatefulWidget {
  const VerbsPage({super.key});

  @override
  State<StatefulWidget> createState() => VerbsPageState();
}

class VerbsPageState extends State<VerbsPage> {
  bool _isLoading = true;
  Verb? _currentVerb;

  @override
  void initState() {
    super.initState();
    context.read<VerbProvider>().initAsync();
  }

  void shuffle() {
    setState(() {
      _currentVerb = context.read<VerbProvider>().random;
    });
  }

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<VerbProvider>();

    if (provider.isInitialized && _currentVerb == null) {
      _currentVerb = provider.items.first;
    }

    return Scaffold(
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
        body: _currentVerb == null ? loading() : body2(context, _currentVerb!));
  }

  Widget body2(BuildContext context, Verb verb) => Column(
        children: [
          SizedBox(
            height: 10.0,
          ),
          Text(
            verb.infinitive,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
          ),
          Text(verb.meaning),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(8),
              children: [
                Card(
                  child: ConjugationView(
                    name: TenseName.present.displayName,
                    tense: verb.present,
                  ),
                ),
                Card(
                  child: ConjugationView(
                    name: TenseName.futur.displayName,
                    tense: verb.futur,
                  ),
                ),
                Card(
                  child: ConjugationView(
                    name: TenseName.passeCompose.displayName,
                    tense: verb.passeCompose,
                  ),
                ),
                Card(
                  child: ConjugationView(
                    name: TenseName.imparfait.displayName,
                    tense: verb.imparfait,
                  ),
                ),
              ],
            ),
          )
        ],
      );

  Widget loading() => Center(
        child: CircularProgressIndicator(),
      );
}
