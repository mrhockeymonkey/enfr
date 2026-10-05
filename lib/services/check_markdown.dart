import 'package:enfr/models/check_response.dart';

/// Renders a streaming Check reply as the markdown the Ask page shows,
/// streaming it token by token.
///
/// Sections come out in [CheckSection] order. Empty sections leave no gap: a
/// section's leading separator is only written once its first text arrives.
Stream<String> checkMarkdown(CheckReply reply) async* {
  var first = true;
  for (final section in CheckSection.values) {
    var started = false;
    await for (final chunk in reply.section(section)) {
      if (chunk.isEmpty) continue;
      if (!started) {
        started = true;
        if (!first) yield '\n\n';
        first = false;
        if (section == CheckSection.meaning) yield 'Signification : « ';
      }
      yield chunk;
    }
    if (started && section == CheckSection.meaning) yield ' »';
  }
}
