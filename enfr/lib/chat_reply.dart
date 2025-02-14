
import 'package:enfr/string_collector.dart';
import 'package:flutter/material.dart';

class ChatReply extends StatefulWidget {
  const ChatReply({required this.reply, super.key});

  final Stream<String> reply;

  @override
  State<StatefulWidget> createState() => _ChatReplyState();

}

class _ChatReplyState extends State<ChatReply> {

  String? cumulativeReply = "";

  @override
  void didUpdateWidget(covariant ChatReply oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    cumulativeReply = "";
  }

  @override
  Widget build(BuildContext context) {

    return StringCollector(stream: widget.reply);

    // return StreamBuilder<String?>(stream: widget.reply, builder: (context, snapshot) {
    //   print("${snapshot.data}");
    //   cumulativeReply = "$cumulativeReply ${snapshot.data}";
    //   return Text("$cumulativeReply");
    // },);
  }
}