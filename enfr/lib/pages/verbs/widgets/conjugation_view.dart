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
  static const double padding = 2.0;

  @override
  Widget build(BuildContext context) => Container(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Text(name),
              ),
            ),
            // const Divider(),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.je ?? ""),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.tu ?? ""),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.il ?? ""),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.nous ?? ""),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.vous ?? ""),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: HighlightedText(value: tense?.ils ?? ""),
            ),
            SizedBox(
              height: 8.0,
            )
          ],
        ),
      );
}
