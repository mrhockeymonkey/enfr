import 'package:enfr/data/verb-provider.dart';
import 'package:enfr/models/verb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerbTest extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _VerbTestState();
}

class _VerbTestState extends State<VerbTest> {
  Verb? _verb;

  @override
  void initState() {
    super.initState();
    context.read<VerbProvider>().initAsync();
  }

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<VerbProvider>();

    if (provider.isInitialized && _verb == null) {
      _verb = provider.random;
    }

    return Column(
      children: [
        Text(
          _verb?.meaning ?? "loading",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30.0,
          ),
        ),
        Text(_verb?.infinitive ?? "loaing"),
      ],
    );
  }
}
