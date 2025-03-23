import 'package:flutter/material.dart';

class StringCollector extends StreamBuilderBase<String, List<String>> {
  const StringCollector(
      {super.key,
      required super.stream,
      required this.onCompleted,
      this.textAlign});

  final ValueChanged<String> onCompleted;
  final TextAlign? textAlign;

  @override
  List<String> initial() => <String>[];

  @override
  List<String> afterConnected(List<String> current) => <String>[];

  @override
  List<String> afterData(List<String> current, String data) =>
      current..add(data);

  @override
  List<String> afterError(
          List<String> current, dynamic error, StackTrace stackTrace) =>
      current..add('error:$error stackTrace:$stackTrace');

  @override
  List<String> afterDone(List<String> current) {
    onCompleted(current.join());
    return current;
  }

  @override
  List<String> afterDisconnected(List<String> current) => current;

  @override
  Widget build(BuildContext context, List<String> currentSummary) => SelectableText(
        currentSummary.join(),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyLarge,
      );
}
