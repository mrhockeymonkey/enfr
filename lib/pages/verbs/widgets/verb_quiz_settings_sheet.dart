import 'package:enfr/models/verb_quiz_settings.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:enfr/models/verb_tier.dart';
import 'package:flutter/material.dart';

class VerbQuizSettingsSheet extends StatefulWidget {
  final VerbQuizSettings settings;
  final ValueChanged<VerbQuizSettings> onChanged;

  const VerbQuizSettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<VerbQuizSettingsSheet> createState() => _VerbQuizSettingsSheetState();
}

class _VerbQuizSettingsSheetState extends State<VerbQuizSettingsSheet> {
  late VerbQuizSettings _settings = widget.settings;

  void _update(VerbQuizSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  void _toggleTier(VerbTier tier, bool enabled) {
    final tiers = {..._settings.tiers};
    enabled ? tiers.add(tier) : tiers.remove(tier);
    _update(_settings.copyWith(tiers: tiers));
  }

  void _toggleTense(VerbTense tense, bool enabled) {
    final tenses = {..._settings.tenses};
    enabled ? tenses.add(tense) : tenses.remove(tense);
    _update(_settings.copyWith(tenses: tenses));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleMedium;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Verb groups', style: heading),
          ),
          for (final tier in VerbTier.values)
            CheckboxListTile(
              title: Text(tier.label),
              subtitle: Text(tier.description),
              value: _settings.tiers.contains(tier),
              onChanged: (v) => _toggleTier(tier, v ?? false),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tenses', style: heading),
          ),
          for (final tense in VerbTense.values)
            CheckboxListTile(
              title: Text(tense.displayName),
              value: _settings.tenses.contains(tense),
              onChanged: (v) => _toggleTense(tense, v ?? false),
            ),
        ],
      ),
    );
  }
}
