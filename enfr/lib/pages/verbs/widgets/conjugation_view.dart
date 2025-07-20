import 'package:enfr/models/tense.dart';
import 'package:flutter/material.dart';

import 'highlighted_text.dart';

class ConjugationView extends StatelessWidget {
  ConjugationView({
    super.key,
    required this.name,
    required this.tense,
  });

  final Tense? tense;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(name),
            ),
            const Divider(),
            HighlightedText(value: tense?.je ?? ""),
            HighlightedText(value: tense?.tu ?? ""),
            HighlightedText(value: tense?.il ?? ""),
            HighlightedText(value: tense?.nous ?? ""),
            HighlightedText(value: tense?.vous ?? ""),
            HighlightedText(value: tense?.ils ?? ""),
          ],
        ),
      );
}
