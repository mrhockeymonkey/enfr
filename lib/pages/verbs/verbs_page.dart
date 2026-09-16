import 'package:enfr/data/verb_repository.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_quiz_settings.dart';
import 'package:enfr/pages/verbs/widgets/question_card.dart';
import 'package:enfr/pages/verbs/widgets/verb_quiz_settings_sheet.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:enfr/services/verb_quiz_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VerbsPage extends StatefulWidget {
  const VerbsPage({super.key});

  @override
  State<VerbsPage> createState() => _VerbsPageState();
}

class _VerbsPageState extends State<VerbsPage> {
  VerbQuizSettings _settings = VerbQuizSettings.defaults;
  List<Verb> _verbs = const [];
  ConjugationQuiz? _quiz;
  ConjugationQuestion? _question;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await VerbQuizSettingsService.load();
    if (!mounted) return;
    _settings = settings;
    await _reloadVerbs();
  }

  Future<void> _reloadVerbs() async {
    setState(() => _loading = true);
    final verbs = await VerbRepository.loadTiers(_settings.tiers);
    if (!mounted) return;
    _verbs = verbs;
    setState(() {
      _rebuildQuiz();
      _loading = false;
    });
  }

  void _rebuildQuiz() {
    final quiz = ConjugationQuiz(verbs: _verbs, tenses: _settings.tenses);
    _quiz = quiz;
    _question = quiz.isEmpty ? null : quiz.next();
  }

  void _onSettingsChanged(VerbQuizSettings settings) {
    final tiersChanged = !setEquals(settings.tiers, _settings.tiers);
    _settings = settings;
    VerbQuizSettingsService.save(settings);
    if (tiersChanged) {
      _reloadVerbs();
    } else {
      setState(_rebuildQuiz);
    }
  }

  void _advance() => setState(() => _question = _quiz!.next());

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => VerbQuizSettingsSheet(
        settings: _settings,
        onChanged: _onSettingsChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verbs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Quiz settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final question = _question;
    if (question == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Select at least one verb group and one tense in settings.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
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
          ),
        ),
      ),
    );
  }
}
