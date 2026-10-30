import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/pages/verbs/widgets/question_card.dart';
import 'package:enfr/pages/verbs/widgets/verb_conjugation_sheet.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:flutter/material.dart';

class VerbQuizPage extends StatefulWidget {
  final Verb verb;
  final Set<VerbTense> tenses;

  const VerbQuizPage({super.key, required this.verb, required this.tenses});

  @override
  State<VerbQuizPage> createState() => _VerbQuizPageState();
}

class _VerbQuizPageState extends State<VerbQuizPage> {
  late ConjugationQuiz _quiz;
  ConjugationQuestion? _question;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _quiz = ConjugationQuiz(verb: widget.verb, tenses: widget.tenses);
    _question = _quiz.next();
  }

  void _advance() =>
      setState(() => _question = _quiz.isFinished ? null : _quiz.next());

  void _openConjugations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => VerbConjugationSheet(verb: widget.verb),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.verb.infinitive),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Show conjugations',
            onPressed: _openConjugations,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final question = _question;
    if (question == null) return _buildFinished(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(question);
        final slide = Tween<Offset>(
          begin: Offset(incoming ? 1 : -1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: QuestionCard(
        key: ValueKey(question),
        question: question,
        onAdvance: _advance,
      ),
    );
  }

  Widget _buildFinished(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Done — ${ConjugationQuiz.questionsPerSession} questions on '
          '${widget.verb.infinitive}',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => setState(_restart),
          child: const Text('Practise again'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Choose another verb'),
        ),
      ],
    );
  }
}
