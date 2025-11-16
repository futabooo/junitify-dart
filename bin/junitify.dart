import 'dart:io';

import 'package:junitify/junitify.dart';

Future<void> main(List<String> arguments) async {
  final runner = DefaultCliRunner(
    parser: const DefaultDartTestParser(),
    generator: const DefaultJUnitXmlGenerator(),
  );

  final exitCode = await runner.run(arguments);
  exit(exitCode);
}
