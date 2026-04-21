import 'package:enfr/data/verb-provider.dart';
import 'package:enfr/pages/ask_chat/ask_page.dart';
import 'package:enfr/pages/settings/settings_page.dart';
import 'package:enfr/pages/verbs/verbs_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => VerbProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      //home: const VerbsPage(),
      home: const AskChatPage(),
      routes: {
        '/verbs': (context) => VerbsPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
