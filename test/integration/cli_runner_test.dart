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

    test('excludes hidden tests from XML output', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"visible test","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","time":200}
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
      expect(content, contains('visible test'));
      expect(content, isNot(contains('hidden test')));
      expect(content, contains('tests="1"'));
    });

    test('outputs debug log for hidden tests when debug mode is enabled', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
''';
      await inputFile.writeAsString(inputJson);

      final outputFile = File('${tempDir.path}/output.xml');

      // Note: In a real scenario, we'd capture stderr, but for now we just verify it doesn't crash
      final exitCode = await runner.run([
        '--input',
        inputFile.path,
        '--output',
        outputFile.path,
        '--debug',
      ]);

      expect(exitCode, equals(0));
      // Note: In a real scenario, we'd capture stderr, but for now we just verify it doesn't crash
    });

    test('handles all tests being hidden', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test 1","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"hidden test 2","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","hidden":true,"time":200}
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
      // Empty test suites should still produce valid XML (may be self-closing tag)
      expect(content, contains('testsuites'));
      // When all tests are hidden, XML may have tests="0" attribute or be empty
      // The XML is valid either way
    });
  });
}
