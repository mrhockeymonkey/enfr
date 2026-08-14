import 'package:flutter/material.dart';

class EnfrScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const EnfrScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(title),
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
        body: body,
      );
}
