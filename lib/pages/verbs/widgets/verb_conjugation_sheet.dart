import 'package:enfr/models/verb.dart';
import 'package:enfr/models/verb_tense.dart';
import 'package:flutter/material.dart';

class VerbConjugationSheet extends StatefulWidget {
  final Verb verb;

  const VerbConjugationSheet({super.key, required this.verb});

  @override
  State<VerbConjugationSheet> createState() => _VerbConjugationSheetState();
}

class _VerbConjugationSheetState extends State<VerbConjugationSheet> {
  late VerbTense _selected = _defaultTense(widget.verb);

  static VerbTense _defaultTense(Verb verb) {
    if (verb.hasTense(VerbTense.present)) return VerbTense.present;
    return VerbTense.values.firstWhere((t) => verb.hasTense(t));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verb = widget.verb;
    final tenses = VerbTense.values.where(verb.hasTense).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Text(
            verb.infinitive,
            style: theme.textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tense in tenses)
                ChoiceChip(
                  label: Text(tense.displayName),
                  selected: _selected == tense,
                  onSelected: (_) => setState(() => _selected = tense),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _ConjugationTable(verb: verb, tense: _selected),
        ],
      ),
    );
  }
}

class _ConjugationTable extends StatelessWidget {
  final Verb verb;
  final VerbTense tense;

  const _ConjugationTable({required this.verb, required this.tense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      for (var i = 0; i < tense.slots.length; i++)
        if (verb.form(tense, i) != null) (tense.slots[i], verb.form(tense, i)!)
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: [
        for (final (label, form) in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  form,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
