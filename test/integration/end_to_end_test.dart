import 'dart:io';

import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('End-to-end conversion', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('junitify_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('converts file to file successfully', () async {
      // Prepare input file
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"example test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      // Run conversion
      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      // Verify output file
      expect(await outputFile.exists(), isTrue);
      final content = await outputFile.readAsString();
      expect(content, contains('<testsuites>'));
      expect(content, contains('test/example_test.dart'));
      expect(content, contains('example test'));
    });

    test('handles failed tests in conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"failure","time":100,"error":"Test failed","stackTrace":"at test:10"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      expect(content, contains('<failure'));
      expect(content, contains('Test failed'));
    });

    test('handles multiple test suites', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/first_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test 1","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":100}
{"type":"suite","suite":{"id":1,"platform":"vm","path":"test/second_test.dart"}}
{"type":"testStart","test":{"id":2,"name":"test 2","suiteID":1},"time":100}
{"type":"testDone","testID":2,"result":"success","time":200}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      await outputDest.writeXml(xmlDoc);

      final content = await outputFile.readAsString();
      expect(content, contains('first_test.dart'));
      expect(content, contains('second_test.dart'));
      expect(content, contains('test 1'));
      expect(content, contains('test 2'));
    });

    test('reports error for non-existent input file', () async {
      final inputSource = FileInputSource('${tempDir.path}/nonexistent.json');
      final result = await inputSource.readJson();

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<FileNotFoundError>());
    });

    test('reports error for invalid JSON', () async {
      final inputFile = File('${tempDir.path}/invalid.json');
      await inputFile.writeAsString('{invalid json}');

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);

      expect(parseResult.isFailure, isTrue);
      expect(parseResult.errorOrNull, isA<JsonSyntaxError>());
    });
  });
}
