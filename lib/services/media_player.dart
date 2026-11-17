import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Plays a local media file through a browser `<audio>` element.
///
/// The file is played from an object URL, so it is never copied into Dart
/// memory — long audiobooks and podcasts are fine.
class MediaPlayer {
  final web.HTMLAudioElement _audio = web.HTMLAudioElement()..preload = 'auto';
  final List<StreamSubscription<web.Event>> _subs = [];
  String? _url;

  /// Whether audio is currently playing.
  final ValueNotifier<bool> playing = ValueNotifier(false);

  /// Total length, known once metadata has loaded.
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  /// Set when the browser cannot decode the file.
  final ValueNotifier<String?> error = ValueNotifier(null);

  MediaPlayer() {
    _subs.addAll([
      web.EventStreamProviders.playEvent
          .forTarget(_audio)
          .listen((_) => playing.value = true),
      web.EventStreamProviders.pauseEvent
          .forTarget(_audio)
          .listen((_) => playing.value = false),
      web.EventStreamProviders.endedEvent
          .forTarget(_audio)
          .listen((_) => playing.value = false),
      web.EventStreamProviders.loadedMetadataEvent
          .forTarget(_audio)
          .listen((_) => duration.value = _toDuration(_audio.duration)),
      const web.EventStreamProvider<web.Event>('error')
          .forTarget(_audio)
          .listen((_) => error.value = 'This audio format is not supported.'),
    ]);
  }

  bool get hasMedia => _url != null;

  Duration get position => _toDuration(_audio.currentTime);

  void loadFile(web.File file) {
    _unload();
    error.value = null;
    duration.value = Duration.zero;
    _url = web.URL.createObjectURL(file);
    _audio.src = _url!;
    _audio.load();
  }

  Future<void> play() async {
    if (!hasMedia) return;
    try {
      await _audio.play().toDart;
    } catch (_) {
      // Interrupted by a pause/seek before playback began; nothing to do.
    }
  }

  void pause() => _audio.pause();

  Future<void> toggle() async => playing.value ? pause() : await play();

  void seek(Duration to) {
    if (!hasMedia) return;
    var seconds = to.inMicroseconds / Duration.microsecondsPerSecond;
    if (seconds < 0) seconds = 0;
    _audio.currentTime = seconds;
  }

  void _unload() {
    _audio.pause();
    _audio.removeAttribute('src');
    final url = _url;
    if (url != null) web.URL.revokeObjectURL(url);
    _url = null;
  }

  void dispose() {
    _unload();
    for (final s in _subs) {
      s.cancel();
    }
    playing.dispose();
    duration.dispose();
    error.dispose();
  }

  static Duration _toDuration(num seconds) => seconds.isFinite
      ? Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round())
      : Duration.zero;
}
