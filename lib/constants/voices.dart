/// An ElevenLabs voice offered in the Listen mode voice picker.
class Voice {
  const Voice(this.id, this.name);

  final String id;
  final String name;
}

/// The voices the Listen mode can use. The first is the default.
const List<Voice> kVoices = [
  Voice('93nuHbke4dTER9x2pDwE', 'Adam'),
];
