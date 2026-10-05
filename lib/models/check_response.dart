import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

/// The sections of a Check reply, in the order the model writes them.
///
/// The enum is the single source of truth: [checkResponseSchema] and the
/// JSON property names are built from it.
enum CheckSection {
  /// The corrected sentence, or the sentence plus a note that it's correct.
  answer,

  /// Why each change was made. Empty when nothing needed correcting.
  explanation,

  /// A more natural Québécois way to say it. Empty when there is none.
  suggestion,

  /// The English meaning of the sentence.
  meaning,
}

/// JSON schema the model must follow for a Check reply.
final Map<String, dynamic> checkResponseSchema = {
  'type': 'object',
  'properties': {
    for (final s in CheckSection.values) s.name: {'type': 'string'},
  },
  'required': [for (final s in CheckSection.values) s.name],
  'additionalProperties': false,
};

/// A complete Check reply.
class CheckResponse {
  const CheckResponse(this._sections);

  final Map<CheckSection, String> _sections;

  String operator [](CheckSection section) => _sections[section] ?? '';

  String get answer => this[CheckSection.answer];
  String get explanation => this[CheckSection.explanation];
  String get suggestion => this[CheckSection.suggestion];
  String get meaning => this[CheckSection.meaning];
}

/// A Check reply that is still streaming in.
class CheckReply {
  CheckReply._() {
    for (final s in CheckSection.values) {
      _sections[s] = _SectionText();
    }
  }

  /// Parses [chunks] of the model's JSON output as they arrive.
  factory CheckReply.fromJsonChunks(Stream<String> chunks) {
    final reply = CheckReply._();
    final source = StreamController<String>();
    final parser = JsonStreamParser(source.stream);

    for (final s in CheckSection.values) {
      final property = parser.getStringProperty(s.name);
      // Unused; it fails if the parser is disposed before the property ends.
      property.future.ignore();
      // TEMP: debug logging, remove when done.
      reply._sections[s]!.done.then(
        (v) => debugPrint('[check] ${s.name} finished: "$v"'),
        onError: (Object e) =>
            debugPrint('[check] ${s.name} failed: $e'),
      );
      property.stream.listen(
        reply._sections[s]!.add,
        onDone: reply._sections[s]!.close,
      );
    }

    chunks.listen(
      source.add,
      // The parser only logs upstream errors, so pass them on ourselves.
      onError: (Object error, StackTrace stackTrace) {
        for (final section in reply._sections.values) {
          section.fail(error, stackTrace);
        }
      },
      onDone: () async {
        await source.close();
        // Section chunks are delivered in microtasks; let them drain before
        // closing whatever the model left unfinished (e.g. truncated output).
        await Future<void>(() {});
        for (final section in reply._sections.values) {
          section.close();
        }
        await parser.dispose();
      },
      cancelOnError: true,
    );

    return reply;
  }

  final Map<CheckSection, _SectionText> _sections = {};

  /// The text of [section] in chunks as it arrives. Late listeners get
  /// everything received so far first.
  Stream<String> section(CheckSection section) => _sections[section]!.stream;

  /// The whole reply, once every section has finished.
  Future<CheckResponse> get done async {
    final values = await Future.wait(
      [for (final s in CheckSection.values) _sections[s]!.done],
    );
    return CheckResponse({
      for (final (i, s) in CheckSection.values.indexed) s: values[i],
    });
  }
}

/// The streamed text of one section: buffers what has arrived so that any
/// number of listeners, early or late, see all of it.
class _SectionText {
  final _buffer = StringBuffer();
  final _live = StreamController<String>.broadcast(sync: true);
  final _done = Completer<String>();

  _SectionText() {
    // A failure reaches listeners of [stream]; don't also report it as
    // unhandled when nobody awaits [done].
    _done.future.ignore();
  }

  void add(String chunk) {
    if (_done.isCompleted) return;
    _buffer.write(chunk);
    _live.add(chunk);
  }

  void close() {
    if (_done.isCompleted) return;
    _done.complete(_buffer.toString());
    _live.close();
  }

  void fail(Object error, StackTrace stackTrace) {
    if (_done.isCompleted) return;
    _done.completeError(error, stackTrace);
    _live
      ..addError(error, stackTrace)
      ..close();
  }

  Future<String> get done => _done.future;

  /// Replays the buffer and subscribes to live chunks in one synchronous
  /// step, so nothing that arrives in between is lost.
  Stream<String> get stream {
    late final StreamController<String> out;
    StreamSubscription<String>? live;
    out = StreamController<String>(
      onListen: () {
        if (_buffer.isNotEmpty) out.add(_buffer.toString());
        if (!_done.isCompleted) {
          live = _live.stream
              .listen(out.add, onError: out.addError, onDone: out.close);
          return;
        }
        _done.future.then(
          (_) => out.close(),
          onError: (Object e, StackTrace s) => out
            ..addError(e, s)
            ..close(),
        );
      },
      onCancel: () => live?.cancel(),
    );
    return out.stream;
  }
}
