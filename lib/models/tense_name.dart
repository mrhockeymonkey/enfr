enum TenseName {
  present(displayName: "Présent"),
  futur(displayName: "Futur"),
  passeCompose(displayName: "Passé Composé"),
  imparfait(displayName: "Imparfait");

  const TenseName({required this.displayName});

  final String displayName;
}
