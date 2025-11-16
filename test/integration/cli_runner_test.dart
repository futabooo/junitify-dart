import 'dart:io';

import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('CLI Runner integration', () {
    late Directory tempDir;
    late DefaultCliRunner runner;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('junitify_cli_test_');
      runner = DefaultCliRunner(
        parser: const DefaultDartTestParser(),
        generator: const DefaultJUnitXmlGenerator(),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('runs successfully with file input and output', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"example test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
''';
      await inputFile.writeAsString(inputJson);

      final outputFile = File('${tempDir.path}/output.xml');

      final exitCode = await runner.run([
        '--input',
        inputFile.path,
        '--output',
        outputFile.path,
      ]);

      expect(exitCode, equals(0));
      expect(await outputFile.exists(), isTrue);
      final content = await outputFile.readAsString();
      expect(content, contains('<testsuites>'));
      expect(content, contains('example test'));
    });

    test('shows help message', () async {
      final exitCode = await runner.run(['--help']);
      expect(exitCode, equals(0));
    });

    test('shows version', () async {
      final exitCode = await runner.run(['--version']);
      expect(exitCode, equals(0));
    });

    test('returns error code for invalid input file', () async {
      final exitCode = await runner.run([
        '--input',
        '${tempDir.path}/nonexistent.json',
        '--output',
        '${tempDir.path}/output.xml',
      ]);

      expect(exitCode, equals(1));
    });

    test('returns error code for invalid JSON', () async {
      final inputFile = File('${tempDir.path}/invalid.json');
      await inputFile.writeAsString('{invalid}');

      final exitCode = await runner.run([
        '--input',
        inputFile.path,
        '--output',
        '${tempDir.path}/output.xml',
      ]);

      expect(exitCode, equals(1));
    });

    test('handles debug mode', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":100}
''';
      await inputFile.writeAsString(inputJson);

      final outputFile = File('${tempDir.path}/output.xml');

      final exitCode = await runner.run([
        '--input',
        inputFile.path,
        '--output',
        outputFile.path,
        '--debug',
      ]);

      expect(exitCode, equals(0));
    });
  });
}
