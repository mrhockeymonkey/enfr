import 'package:enfr/chat_reply.dart';
import 'package:flutter/material.dart';
import 'package:mistralai_client_dart/mistralai_client_dart.dart';

class AskChatPage extends StatefulWidget {
  const AskChatPage({super.key});

  @override
  State<AskChatPage> createState() => _AskChatPageState();
}

class _AskChatPageState extends State<AskChatPage> {
  int _counter = 0;
  bool _showExplainBtn = false;
  String _answerText = "";
  late Stream<String> _answerStream;
  late Stream<String> _explanationStream;
  late TextEditingController _controller;

  @override
  void initState() {
    // TODO: implement initState
    //_answer = _mockReply();
    _answerStream = Stream.empty();
    _explanationStream = Stream.empty();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<String> _mockReply() async* {
    final interval = Duration(milliseconds: 200);
    for (var i = 0; i < 5; i++) {
      yield "The\n";
      await Future.delayed(interval);
      yield "Quick\n";
      await Future.delayed(interval);
      yield "Brown\n";
      await Future.delayed(interval);
      yield "Fox\n";
      await Future.delayed(interval);
      yield "Jumped\n";
      await Future.delayed(interval);
    }
  }

  Stream<int> timedCounter(Duration interval, [int? maxCount]) async* {
    int i = 0;
    while (true) {
      await Future.delayed(interval);
      yield i++;
      if (i == maxCount) break;
    }
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _answerStream = _askChat("THE BUTTON WAS PRESSED");
    });
  }

  Stream<String> _askChat(String content) async* {
    final client = MistralAIClient(apiKey: "");

    var request = AgentsCompletionRequest(
      agentId: 'ag:6f5b526f:20250211:untitled-agent:854962cb',
      messages: [
        UserMessage(content: UserMessageContent.string(content)),
      ],
    );

    final stream = client.agentsStream(request: request);
    await for (final completionChunk in stream) {
      final chatMessage = completionChunk.choices[0].delta.content;
      print(chatMessage);
      yield chatMessage ?? ""; // or not yield...
      await Future.delayed(Duration(milliseconds: 100));
      // if (chatMessage != null) {
      //   print(chatMessage);
      // }
    }
  }

  Stream<String> _askChatExplain(String content) async* {
    final client = MistralAIClient(apiKey: "");

    var request = AgentsCompletionRequest(
      agentId: 'ag:6f5b526f:20250216:explain:819d1d96',
      messages: [
        UserMessage(content: UserMessageContent.string(content)),
      ],
    );

    final stream = client.agentsStream(request: request);
    await for (final completionChunk in stream) {
      final chatMessage = completionChunk.choices[0].delta.content;
      print(chatMessage);
      yield chatMessage ?? ""; // or not yield...
      await Future.delayed(Duration(milliseconds: 100));
      // if (chatMessage != null) {
      //   print(chatMessage);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Traduire"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Header")),
            ListTile(
              title: Text("Verbs"),
              onTap: () => Navigator.of(context).pushNamed("/verbs"),
            ),
          ],
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 35.0, horizontal: 10.0),
          child: Column(
            verticalDirection: VerticalDirection.down,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.copyWith(
                              bodyLarge: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                      ),
                      child: ChatReply(
                        reply: _answerStream,
                        textAlign: TextAlign.center,
                        onCompleted: (value) => setState(() {
                          _answerText = value;
                          if (_answerText.isNotEmpty) _showExplainBtn = true;
                        }),
                      ),
                    ),
                    _showExplainBtn
                        ? TextButton(
                            onPressed: () => setState(() => _explanationStream =
                                _askChatExplain(_answerText)),
                            child: Text("explain"),
                          )
                        : Container(),
                    ChatReply(reply: _explanationStream)
                  ],
                ),
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                    hintText: "Que veux-tu dire?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _controller.clear(),
                      icon: Icon(Icons.clear),
                    )),
                onSubmitted: (value) =>
                    setState(() => _answerStream = _askChat(value)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
