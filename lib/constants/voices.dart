/// An ElevenLabs voice offered in the Listen mode voice picker.
class Voice {
  const Voice(this.id, this.name);

  final String id;
  final String name;
}

/// The voices the Listen mode can use. The first is the default.
const List<Voice> kVoices = [
  Voice('93nuHbke4dTER9x2pDwE', 'Adam'),
  Voice('GMiYOSKrjrtKjU1G8xyM', 'Kasandra'),
  Voice('KbgdAMqTSb5aaLUaXEm2', 'Antoine'),
  Voice('WW0JfNPk5DgcQdM0d6X6', 'Claudia'),
  Voice('UJCi4DDncuo0VJDSIegj', 'Amelie'),
  Voice('mVjOqyqTPfwlXPjV5sjX', 'Thierry'),
];
