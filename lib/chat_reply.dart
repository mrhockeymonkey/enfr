import 'package:enfr/string_collector.dart';
import 'package:flutter/material.dart';

class ChatReply extends StatefulWidget {
  const ChatReply({
    super.key, 
    required this.reply, 
    this.textAlign,
    this.onCompleted = _defaultOnCompleted});

  final Stream<String> reply;
  final TextAlign? textAlign;
  final ValueChanged<String> onCompleted;
  //final ValueChanged<String>() onCompleted;

  @override
  State<StatefulWidget> createState() => _ChatReplyState();

  static void _defaultOnCompleted(String _) {}
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
    return Card(
      elevation: 0.0,
      color: Colors.transparent,
      child: StringCollector(
        stream: widget.reply,
        textAlign: widget.textAlign,
        onCompleted: widget.onCompleted,
      ),
    );

    // return StreamBuilder<String?>(stream: widget.reply, builder: (context, snapshot) {
    //   print("${snapshot.data}");
    //   cumulativeReply = "$cumulativeReply ${snapshot.data}";
    //   return Text("$cumulativeReply");
    // },);
  }
}
