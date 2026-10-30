import 'package:enfr/models/verb_tense.dart';
import 'package:flutter/material.dart';

/// Hue for each tense, so a tense looks the same in the quiz and the
/// conjugation sheet. The past tenses are warm, the future cool and the
/// subjunctives purple, with neighbours kept far enough apart to tell at a
/// glance.
const _seeds = {
  VerbTense.present: Colors.green,
  VerbTense.passeCompose: Colors.orange,
  VerbTense.imparfait: Colors.amber,
  VerbTense.futur: Colors.blue,
  VerbTense.conditionnel: Colors.indigo,
  VerbTense.passeSimple: Colors.red,
  VerbTense.subjonctifPresent: Colors.purple,
  VerbTense.subjonctifImparfait: Colors.pink,
  VerbTense.imperatif: Colors.cyan,
  VerbTense.pastParticiple: Colors.brown,
};

final _schemes = <(VerbTense, Brightness), ColorScheme>{};

/// A Material scheme seeded from the tense's hue, cached because
/// [ColorScheme.fromSeed] is not cheap.
ColorScheme _schemeFor(VerbTense tense, Brightness brightness) =>
    _schemes.putIfAbsent(
      (tense, brightness),
      () => ColorScheme.fromSeed(
        seedColor: _seeds[tense]!,
        brightness: brightness,
        // The default variant mutes the seed, which left the warm tenses
        // looking alike; fidelity keeps each hue close to its seed.
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
    );

/// A tense's name in its own colour. With [onSelected] it is a choice chip
/// that shows [selected] by filling in; without it, a filled label.
class TenseChip extends StatelessWidget {
  final VerbTense tense;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const TenseChip({
    super.key,
    required this.tense,
    this.selected = true,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(tense, Theme.of(context).brightness);
    final label = Text(
      tense.displayName,
      style: TextStyle(
        color: selected ? scheme.onPrimaryContainer : scheme.primary,
      ),
    );
    final side = BorderSide(color: scheme.primary);

    if (onSelected == null) {
      return Chip(
        label: label,
        backgroundColor: scheme.primaryContainer,
        side: side,
      );
    }
    return ChoiceChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      side: side,
    );
  }
}
