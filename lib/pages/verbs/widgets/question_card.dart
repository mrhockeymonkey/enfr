import 'dart:math';

import 'package:enfr/pages/verbs/widgets/tense_chip.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

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

  /// The prompt with the answer typed straight into its blank, like a
  /// worksheet on paper. The blank starts at a fixed width, so it gives away
  /// nothing about the answer, and grows as the user types.
  Widget _buildSentence(ThemeData theme) {
    final (before, after) = widget.question.prompt;
    final style = theme.textTheme.headlineSmall;
    final wrong = _attempts > 0 && !_revealed;
    UnderlineInputBorder underline(Color color, [double width = 1]) =>
        UnderlineInputBorder(
          borderSide: BorderSide(
              color: wrong ? theme.colorScheme.error : color,
              width: wrong ? 2 : width),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (before.isNotEmpty) Text(before, style: style),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120),
            child: IntrinsicWidth(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textAlign: TextAlign.center,
                style: style,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  enabledBorder: underline(theme.colorScheme.onSurfaceVariant),
                  focusedBorder: underline(theme.colorScheme.primary, 2),
                ),
                onSubmitted: _submit,
              ),
            ),
          ),
        ),
        if (after.isNotEmpty) Text(after, style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.question;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A real link (an <a> on web) rather than a launchUrl call, so a tap
        // on Android can hand off to the WordReference app if installed.
        Link(
          uri: question.verb.wordReferenceUrl,
          target: LinkTarget.blank,
          builder: (context, followLink) => InkWell(
            onTap: followLink,
            borderRadius: BorderRadius.circular(8),
            child: Text(
              question.verb.infinitive,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationThickness: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Question ${question.number} of ${ConjugationQuiz.questionsPerSession}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TenseChip(tense: question.tense),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = sin(t * pi * 4) * 8 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: _buildSentence(theme),
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
