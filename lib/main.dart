import 'package:enfr/data/prompt_repository.dart';
import 'package:enfr/pages/ask_chat/ask_page.dart';
import 'package:enfr/pages/journal/journal_page.dart';
import 'package:enfr/pages/settings/settings_page.dart';
import 'package:enfr/pages/verbs/verbs_page.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PromptRepository.initAsync();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        platform: TargetPlatform.android,
        typography: Typography.material2021(platform: TargetPlatform.android),
        drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),
        listTileTheme: ListTileThemeData(
          textColor: scheme.onSurface,
          iconColor: scheme.onSurfaceVariant,
        ),
      ),
      home: const AskChatPage(),
      routes: {
        '/verbs': (context) => const VerbsPage(),
        '/journal': (context) => const JournalPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
