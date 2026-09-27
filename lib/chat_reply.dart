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

class _ChatReplyState extends State<ChatReply>
    with AutomaticKeepAliveClientMixin {
  String? cumulativeReply = "";

  /// Replies live in a lazy ListView, which disposes children scrolled
  /// off-screen. The reply stream is single-subscription, so a rebuilt
  /// StringCollector re-listening to it would throw; keep this state alive.
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant ChatReply oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    cumulativeReply = "";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
