import 'package:enfr/chat_reply.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A lazy ListView disposes children scrolled off-screen. The reply stream is
  // single-subscription, so a rebuilt ChatReply re-listening to it would throw
  // "Stream has already been listened to" (a grey error box in release).
  testWidgets('ChatReply survives being scrolled off-screen and back',
      (tester) async {
    Stream<String> reply() async* {
      yield List.filled(80, 'line').join('\n\n');
    }

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            ChatReply(reply: reply()),
            const SizedBox(height: 3000),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable);
    await tester.drag(list, const Offset(0, -6000));
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, 6000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('line', findRichText: true), findsWidgets);
  });
}
