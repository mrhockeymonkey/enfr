import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Plays a single audio clip in the browser, keeping it so it can be replayed
/// without fetching it again. Loading a new clip replaces the previous one.
class ClipPlayer {
  final web.HTMLAudioElement _audio = web.HTMLAudioElement();
  String? _url;

  bool get hasClip => _url != null;

  void load(Uint8List mp3) {
    clear();
    final blob = web.Blob(
      [mp3.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/mpeg'),
    );
    _url = web.URL.createObjectURL(blob);
    _audio.src = _url!;
  }

  Future<void> play() async {
    if (!hasClip) return;
    _audio.currentTime = 0;
    await _audio.play().toDart;
  }

  /// Stops and drops the current clip.
  void clear() {
    _audio.pause();
    _audio.removeAttribute('src');
    final url = _url;
    if (url != null) web.URL.revokeObjectURL(url);
    _url = null;
  }

  void dispose() => clear();
}
