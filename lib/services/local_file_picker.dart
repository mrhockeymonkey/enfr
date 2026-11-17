import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _subtitleExtensions = {'srt', 'vtt'};
const _audioExtensions = {
  'mp3', 'm4a', 'm4b', 'aac', 'ogg', 'oga', 'opus', 'wav', 'flac', 'mp4',
  'webm', //
};

/// What the `accept` attribute offers in the picker for audio + subtitles.
const mediaAccept =
    'audio/*,video/mp4,video/webm,.srt,.vtt,text/vtt,application/x-subrip';

/// Opens the browser's file picker and resolves with the chosen files, or an
/// empty list if the user cancels.
Future<List<web.File>> pickFiles({
  String accept = '',
  bool multiple = false,
}) {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = multiple
    ..style.display = 'none';
  // Some mobile browsers only open the picker for inputs in the document.
  web.document.body?.append(input);

  final completer = Completer<List<web.File>>();
  late final StreamSubscription<web.Event> changeSub;
  late final StreamSubscription<web.Event> cancelSub;
  void finish(List<web.File> files) {
    if (completer.isCompleted) return;
    changeSub.cancel();
    cancelSub.cancel();
    input.remove();
    completer.complete(files);
  }

  changeSub = web.EventStreamProviders.changeEvent.forTarget(input).listen((_) {
    final list = input.files;
    finish([
      if (list != null)
        for (var i = 0; i < list.length; i++) list.item(i)!,
    ]);
  });
  cancelSub = web.EventStreamProviders.cancelEvent
      .forTarget(input)
      .listen((_) => finish(const []));

  input.click();
  return completer.future;
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

bool isSubtitleFile(web.File f) =>
    _subtitleExtensions.contains(_extension(f.name));

bool isAudioFile(web.File f) =>
    !isSubtitleFile(f) &&
    (f.type.startsWith('audio/') ||
        f.type.startsWith('video/') ||
        _audioExtensions.contains(_extension(f.name)));

Future<String> readFileAsText(web.File f) async => (await f.text().toDart).toDart;
