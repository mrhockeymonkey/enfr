import 'package:enfr/models/subtitle_cue.dart';
import 'package:enfr/services/local_file_picker.dart';
import 'package:enfr/services/media_player.dart';
import 'package:enfr/services/sentence_navigator.dart';
import 'package:enfr/services/subtitle_parser.dart';
import 'package:enfr/pages/player/speed_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Plays a local audio file alongside its subtitles, navigating by sentence
/// (subtitle cue) rather than by time.
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  /// How long auto-scroll stays off after the user scrolls the transcript.
  static const _manualScrollHold = Duration(seconds: 3);

  final MediaPlayer _player = MediaPlayer();
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  late final Ticker _ticker = createTicker((_) => _syncPosition());

  List<SubtitleCue> _cues = const [];
  List<GlobalKey> _cueKeys = const [];
  String? _audioName;
  String? _subtitleName;
  int? _active;
  bool _loading = false;
  DateTime _lastManualScroll = DateTime.fromMillisecondsSinceEpoch(0);

  /// Slider value while the user is dragging it, so it doesn't jump back.
  double? _dragSeconds;

  @override
  void initState() {
    super.initState();
    _player.playing.addListener(_onPlayingChanged);
    _player.error.addListener(_onError);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _player.playing.removeListener(_onPlayingChanged);
    _player.error.removeListener(_onError);
    _player.dispose();
    _position.dispose();
    super.dispose();
  }

  void _onPlayingChanged() {
    if (_player.playing.value) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
      _syncPosition();
    }
  }

  void _onError() {
    final message = _player.error.value;
    if (message != null) _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Reads the playhead and updates the highlighted cue if it changed.
  void _syncPosition() {
    final pos = _player.position;
    _position.value = pos;
    final index = activeIndex(_cues, pos);
    if (index != _active) {
      setState(() => _active = index);
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    final index = _active;
    if (index == null) return;
    if (DateTime.now().difference(_lastManualScroll) < _manualScrollHold) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cueKeys[index].currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _load() async {
    final files = await pickFiles(accept: mediaAccept, multiple: true);
    if (files.isEmpty) return;

    final audio = files.where(isAudioFile).firstOrNull;
    final subtitles = files.where(isSubtitleFile).firstOrNull;
    if (audio == null && subtitles == null) {
      _showMessage('Choose an audio file and an .srt or .vtt subtitle file.');
      return;
    }
    if (audio == null && !_player.hasMedia) {
      _showMessage('No audio file selected — choose one along with subtitles.');
      return;
    }

    setState(() => _loading = true);
    try {
      var cues = _cues;
      if (subtitles != null) {
        cues = parseSubtitles(await readFileAsText(subtitles));
        if (cues.isEmpty) {
          _showMessage('No subtitles found in ${subtitles.name}.');
        }
      } else if (audio != null) {
        // New audio without subtitles: old subtitles won't match it.
        cues = const [];
      }

      if (audio != null) {
        _player.loadFile(audio);
        _audioName = audio.name;
        if (subtitles == null) {
          _subtitleName = null;
          _showMessage(
              'No subtitle file selected — sentence navigation is off.');
        }
      }
      if (subtitles != null) _subtitleName = subtitles.name;

      _cues = cues;
      _cueKeys = List.generate(cues.length, (_) => GlobalKey());
      _active = null;
      _position.value = Duration.zero;
      if (audio == null) _player.seek(Duration.zero);
    } catch (e) {
      _showMessage('Could not load files: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _syncPosition();
  }

  void _seek(Duration to) {
    _player.seek(to);
    _lastManualScroll = DateTime.fromMillisecondsSinceEpoch(0);
    _syncPosition();
  }

  void _previous() {
    final target = previousTarget(_cues, _player.position);
    if (target != null) _seek(target);
  }

  void _next() {
    final target = nextTarget(_cues, _player.position);
    if (target != null) _seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _player.hasMedia;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _previous,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.space): _player.toggle,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Player'),
            actions: [
              IconButton(
                tooltip: 'Load audio & subtitles',
                icon: const Icon(Icons.folder_open),
                onPressed: _loading ? null : _load,
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : loaded
                  ? Column(
                      children: [
                        _fileInfo(context),
                        Expanded(child: _transcript(context)),
                        _controls(context),
                      ],
                    )
                  : _emptyState(context),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Icon(Icons.headphones,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const Text(
              'Choose an audio file and its subtitles (.srt or .vtt) '
              'to listen sentence by sentence.',
              textAlign: TextAlign.center,
            ),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.folder_open),
              label: const Text('Load audio & subtitles'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileInfo(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.audiotrack, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(_audioName ?? '',
                  style: style, overflow: TextOverflow.ellipsis),
            ),
          ]),
          Row(children: [
            const Icon(Icons.subtitles, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(_subtitleName ?? 'No subtitles',
                  style: style, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _transcript(BuildContext context) {
    if (_cues.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No subtitles loaded.\nTap the folder icon to add an .srt or '
            '.vtt file.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return NotificationListener<ScrollStartNotification>(
      onNotification: (n) {
        if (n.dragDetails != null) _lastManualScroll = DateTime.now();
        return false;
      },
      // A non-lazy column so every cue has a context for ensureVisible.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _cues.length; i++)
              _cueTile(i, scheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _cueTile(int i, ColorScheme scheme, TextTheme textTheme) {
    final active = i == _active;
    final past = _active != null && i < _active!;
    final style = textTheme.bodyLarge?.copyWith(
      fontWeight: active ? FontWeight.bold : FontWeight.normal,
      color: active
          ? scheme.onPrimaryContainer
          : past
              ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
              : scheme.onSurface,
    );
    return Padding(
      key: _cueKeys[i],
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seek(_cues[i].start),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(_cues[i].text, style: style),
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCues = _cues.isNotEmpty;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<Duration>(
                valueListenable: _player.duration,
                builder: (context, total, _) =>
                    ValueListenableBuilder<Duration>(
                  valueListenable: _position,
                  builder: (context, pos, _) => _seekBar(pos, total),
                ),
              ),
              // Equal flexible sides keep the transport buttons centred,
              // while the speed pill lives in its own slot and so can never
              // overlap them; it scales down if the screen is very narrow.
              Row(
                children: [
                  const Spacer(),
                  _transportButtons(hasCues),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _speedButton(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transportButtons(bool hasCues) {
    return ValueListenableBuilder<bool>(
      valueListenable: _player.playing,
      builder: (context, playing, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous sentence',
            iconSize: 32,
            onPressed: hasCues ? _previous : null,
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton.filled(
            tooltip: playing ? 'Pause' : 'Play',
            iconSize: 48,
            onPressed: _player.toggle,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          ),
          IconButton.filledTonal(
            tooltip: 'Next sentence',
            iconSize: 32,
            onPressed: hasCues ? _next : null,
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    );
  }

  /// Compact pill showing the current speed; opens the speed sheet.
  Widget _speedButton(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _player.speed,
      builder: (context, speed, _) => MergeSemantics(
        child: Semantics(
          label: 'Playback speed',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
            icon: const Icon(Icons.speed, size: 16),
            label: Text(formatSpeed(speed)),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => SpeedSheet(player: _player),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seekBar(Duration pos, Duration total) {
    final max = total.inMilliseconds / 1000.0;
    final value = (_dragSeconds ?? pos.inMilliseconds / 1000.0)
        .clamp(0.0, max > 0 ? max : 0.0);
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(_format(Duration(milliseconds: (value * 1000).round())),
              style: labelStyle, textAlign: TextAlign.center),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: max > 0 ? max : 1,
            onChanged: max > 0 ? (v) => setState(() => _dragSeconds = v) : null,
            onChangeEnd: (v) {
              setState(() => _dragSeconds = null);
              _seek(Duration(milliseconds: (v * 1000).round()));
            },
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(_format(total),
              style: labelStyle, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
