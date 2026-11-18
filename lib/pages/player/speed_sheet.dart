import 'package:enfr/services/media_player.dart';
import 'package:flutter/material.dart';

/// Formats a speed multiplier as e.g. `0.95×` or `1.0×`.
String formatSpeed(double speed) {
  var text = speed.toStringAsFixed(2);
  if (text.endsWith('0')) text = text.substring(0, text.length - 1);
  return '$text×';
}

/// Pull-up sheet for adjusting playback speed: a large readout, minus/plus
/// steppers either side of a slider, and quick presets.
class SpeedSheet extends StatelessWidget {
  const SpeedSheet({super.key, required this.player});

  final MediaPlayer player;

  static const double _step = 0.01;
  static const List<double> _presets = [0.9, 0.95, 1.0];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const min = MediaPlayer.minSpeed;
    const max = MediaPlayer.maxSpeed;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ValueListenableBuilder<double>(
          valueListenable: player.speed,
          builder: (context, speed, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Playback speed', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(formatSpeed(speed), style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Slower',
                    onPressed: speed > min + 1e-9
                        ? () => player.setSpeed(speed - _step)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      value: speed.clamp(min, max),
                      min: min,
                      max: max,
                      divisions: ((max - min) / _step).round(),
                      label: formatSpeed(speed),
                      onChanged: player.setSpeed,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Faster',
                    onPressed: speed < max - 1e-9
                        ? () => player.setSpeed(speed + _step)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in _presets)
                    ChoiceChip(
                      label:
                          Text(preset == 1.0 ? 'Normal' : formatSpeed(preset)),
                      selected: (speed - preset).abs() < 1e-9,
                      onSelected: (_) => player.setSpeed(preset),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
