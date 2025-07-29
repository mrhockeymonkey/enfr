import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  HighlightedText({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    var isHighlighted = false;
    var parts = value.split('`');

    List<TextSpan> spans = parts.map((s) {
      var span = isHighlighted
          ? TextSpan(
              text: s,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )
          : TextSpan(text: s);
      isHighlighted = !isHighlighted;
      return span;
    }).toList();

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 18, color: Colors.black),
        children: spans,
      ),
    );
  }
}
