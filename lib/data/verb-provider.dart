import 'dart:collection';
import 'dart:math';

import 'package:enfr/models/verb.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';

class VerbProvider with ChangeNotifier {
  List<Verb> _items = [];
  int _itemCount = 0;
  bool _isInitialized = false;
  final Random _rnd = Random();

  UnmodifiableListView<Verb> get items => UnmodifiableListView(_items);
  Verb get random => _items[_rnd.nextInt(_itemCount)];
  bool get isInitialized => _isInitialized;

  Future initAsync() async {
    if (_isInitialized) return;

    final String yaml = await rootBundle.loadString('assets/verbs.yaml');
    final Map verbData = loadYaml(yaml) as Map;
    final List<dynamic> rawVerbs = verbData['verbs'];
    List<Verb> verbs = rawVerbs.map((e) => Verb.fromYaml(e)).toList();

    _items = verbs;
    _itemCount = _items.length;
    _isInitialized = true;

    notifyListeners();
  }
}
