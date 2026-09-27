import 'package:enfr/chat_reply.dart';
import 'package:enfr/constants/app_version.dart';
import 'package:enfr/constants/prompts.dart';
import 'package:enfr/data/prompt_repository.dart';
import 'package:enfr/services/api_key_service.dart';
import 'package:enfr/services/model_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:mistralai_client_dart/mistralai_client_dart.dart';

/// What the Ask page does with the text input: which prompt template (if any)
/// wraps it before it is sent.
/// Shared by the mode chip and the text input so they have the same shape.
const _kInputRadius = BorderRadius.all(Radius.circular(25.0));

enum AskMode {
  translate('Translate', Icons.translate),
  check('Check', Icons.spellcheck),
  chat('Chat', Icons.chat_bubble_outline);

  const AskMode(this.label, this.icon);

  final String label;
  final IconData icon;

  /// The prompt template for this mode, or null to send the input as-is.
  String? get promptTemplate => switch (this) {
        AskMode.translate => PromptRepository.translatePrompt,
        AskMode.check => PromptRepository.checkPrompt,
        AskMode.chat => null,
      };
}

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
  AskMode _mode = AskMode.translate;

  /// The mode the current answer was asked in; decides how it is displayed,
  /// so switching the chip afterwards doesn't restyle an existing answer.
  AskMode _answerMode = AskMode.translate;

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitQuestion(String content) async {
    final key = await ApiKeyService.loadKey();
    if (!mounted) return;
    if (key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add your Mistral API key in Settings first')));
      return;
    }
    setState(() {
      _answerMode = _mode;
      _answerStream = _askChat(content);
      _answerText = "";
      _showExplainBtn = false;
      _explanationStream = Stream.empty();
    });
  }

  Future<void> _submitExplain(String content) async {
    final key = await ApiKeyService.loadKey();
    if (!mounted) return;
    if (key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add your Mistral API key in Settings first')));
      return;
    }
    setState(() => _explanationStream = _askChatExplain(content));
  }

  Stream<String> _askChat(String content) async* {
    final key = await ApiKeyService.loadKey() ?? '';
    final model = await ModelPreferenceService.loadModel();
    final client = MistralAIClient(apiKey: key);

    final promptTemplate = _mode.promptTemplate;

    var request = ChatCompletionRequest(
      model: model,
      temperature: 0,
      messages: [
        UserMessage(
          content: UserMessageContent.string(
            promptTemplate == null
                ? content
                : promptTemplate.replaceFirst(
                    kTranslatePromptInputPlaceholder, content),
          ),
        ),
      ],
    );

    final stream = client.chatStream(request: request);
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
    final key = await ApiKeyService.loadKey() ?? '';
    final model = await ModelPreferenceService.loadModel();
    final client = MistralAIClient(apiKey: key);

    var request = ChatCompletionRequest(
      model: model,
      temperature: 0,
      messages: [
        SystemMessage(content: Content.string(PromptRepository.explainPrompt)),
        UserMessage(content: UserMessageContent.string(content)),
      ],
    );

    final stream = client.chatStream(request: request);
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

  void _openModePicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            for (final mode in AskMode.values)
              ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                leading: Icon(mode.icon),
                title: Text(mode.label),
                trailing: mode == _mode ? const Icon(Icons.check) : null,
                selected: mode == _mode,
                onTap: () {
                  setState(() => _mode = mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// A regular-weight markdown reply, with headings kept at body size rather
  /// than headline sizes. Used for explanations and check/chat answers.
  Widget _plainReply(Stream<String> reply) {
    final heading = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontWeight: FontWeight.bold);
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownThemeData(
        brightness: Theme.of(context).brightness,
        h1: heading,
        h2: heading,
        h3: heading,
        h4: heading,
        h5: heading,
        h6: heading,
      ),
      child: ChatReply(reply: reply),
    );
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  DrawerHeader(child: Text("Header")),
                  ListTile(
                    title: Text("Verbs"),
                    onTap: () => Navigator.of(context).pushNamed("/verbs"),
                  ),
                  ListTile(
                    title: Text("Journal"),
                    onTap: () => Navigator.of(context).pushNamed("/journal"),
                  ),
                  ListTile(
                    title: Text("Settings"),
                    onTap: () => Navigator.of(context).pushNamed("/settings"),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'v$appVersion+$appBuildNumber',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
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
                    if (_answerMode == AskMode.translate) ...[
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
                              onPressed: () => _submitExplain(_answerText),
                              child: Text("explain"),
                            )
                          : Container(),
                      _plainReply(_explanationStream),
                    ] else
                      _plainReply(_answerStream),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ActionChip(
                    shape: const RoundedRectangleBorder(
                      borderRadius: _kInputRadius,
                    ),
                    avatar: Icon(_mode.icon, size: 18),
                    label: Text(_mode.label),
                    tooltip: 'Choose mode',
                    onPressed: _openModePicker,
                  ),
                ),
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                    hintText: switch (_mode) {
                      AskMode.translate => "What do you want to say?",
                      AskMode.check => "Que veux-tu vérifier?",
                      AskMode.chat => "Ask anything",
                    },
                    border: OutlineInputBorder(
                      borderRadius: _kInputRadius,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => _controller.clear(),
                      icon: Icon(Icons.clear),
                    )),
                onSubmitted: (value) => _submitQuestion(value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
