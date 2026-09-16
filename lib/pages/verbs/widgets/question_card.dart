import 'dart:math';

import 'package:enfr/services/conjugation_quiz.dart';
import 'package:flutter/material.dart';

class QuestionCard extends StatefulWidget {
  final ConjugationQuestion question;
  final VoidCallback onAdvance;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onAdvance,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  int _attempts = 0;
  bool _revealed = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (_revealed || widget.question.matches(value)) {
      widget.onAdvance();
      return;
    }
    setState(() => _attempts++);
    _shake.forward(from: 0);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _focusNode.requestFocus();
  }

  void _reveal() {
    setState(() => _revealed = true);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.question;
    final errorBorder = _attempts > 0 && !_revealed
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          question.verb.infinitive,
          style: theme.textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Question ${question.number} of ${ConjugationQuiz.questionsPerVerb}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        Text(
          question.prompt,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = sin(t * pi * 4) * 8 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Type the conjugation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: errorBorder,
              focusedBorder: errorBorder,
            ),
            onSubmitted: _submit,
          ),
        ),
        const SizedBox(height: 16),
        if (_revealed) ...[
          Text(
            question.answer,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: widget.onAdvance,
            child: const Text('Next'),
          ),
        ] else if (_attempts > 0)
          TextButton(
            onPressed: _reveal,
            child: const Text('Reveal'),
          ),
      ],
    );
  }
}
