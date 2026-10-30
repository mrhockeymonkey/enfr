import 'dart:math';

import 'package:enfr/data/verb_repository.dart';
import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_quiz_settings.dart';
import 'package:enfr/pages/verbs/verb_quiz_page.dart';
import 'package:enfr/pages/verbs/widgets/verb_quiz_settings_sheet.dart';
import 'package:enfr/services/conjugation_quiz.dart';
import 'package:enfr/services/verb_quiz_settings_service.dart';
import 'package:enfr/services/verb_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VerbsPage extends StatefulWidget {
  const VerbsPage({super.key});

  @override
  State<VerbsPage> createState() => _VerbsPageState();
}

class _VerbsPageState extends State<VerbsPage> {
  final _searchController = TextEditingController();
  final _random = Random();

  VerbQuizSettings _settings = VerbQuizSettings.defaults;
  List<Verb> _loaded = const [];

  /// Loaded verbs that have at least one enabled tense.
  List<Verb> _verbs = const [];
  List<Verb> _matches = const [];

  /// The verb to practise; null means pick one at random on Start.
  Verb? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    _loaded = verbs;
    setState(() {
      _rebuildPool();
      _loading = false;
    });
  }

  void _rebuildPool() {
    _verbs = [
      for (final v in _loaded)
        if (ConjugationQuiz.canQuiz(v, _settings.tenses)) v
    ];
    if (_selected != null && !_verbs.contains(_selected)) _selected = null;
    _search();
  }

  void _search() => _matches = searchVerbs(_verbs, _searchController.text);

  void _onSettingsChanged(VerbQuizSettings settings) {
    final tiersChanged = !setEquals(settings.tiers, _settings.tiers);
    _settings = settings;
    VerbQuizSettingsService.save(settings);
    if (tiersChanged) {
      _reloadVerbs();
    } else {
      setState(_rebuildPool);
    }
  }

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

  void _select(Verb? verb) =>
      setState(() => _selected = _selected == verb ? null : verb);

  void _start() {
    final verb = _selected ?? _verbs[_random.nextInt(_verbs.length)];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerbQuizPage(verb: verb, tenses: _settings.tenses),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            heightFactor: 1,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(_selected == null
                  ? 'Start (random verb)'
                  : 'Start: ${_selected!.infinitive}'),
              onPressed: _loading || _verbs.isEmpty ? null : _start,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_verbs.isEmpty) {
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Search ${_verbs.length} verbs',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _search();
                          }),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                onChanged: (_) => setState(_search),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Random'),
              subtitle: const Text('Pick a verb for me'),
              selected: _selected == null,
              onTap: () => _select(null),
            ),
            const Divider(height: 1),
            Expanded(
              child: _matches.isEmpty
                  ? const Center(child: Text('No matching verbs'))
                  : ListView.builder(
                      itemCount: _matches.length,
                      itemBuilder: (context, i) {
                        final verb = _matches[i];
                        return ListTile(
                          title: Text(verb.infinitive),
                          subtitle: Text(verb.tier.label),
                          selected: verb == _selected,
                          onTap: () => _select(verb),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
