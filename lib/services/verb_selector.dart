import 'dart:math';

import 'package:enfr/models/verb.dart';

abstract interface class VerbSelector {
  Verb next(List<Verb> pool);
}

class RandomVerbSelector implements VerbSelector {
  final Random _random;

  RandomVerbSelector([Random? random]) : _random = random ?? Random();

  @override
  Verb next(List<Verb> pool) => pool[_random.nextInt(pool.length)];
}
