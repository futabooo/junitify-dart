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

    test('excludes hidden tests from XML conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"visible test","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","time":200}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      final testResult = parseResult.valueOrNull!;
      expect(testResult.totalTests, equals(1));
      expect(testResult.suites.first.testCases.length, equals(1));
      expect(testResult.suites.first.testCases.first.name, equals('visible test'));

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(testResult);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      expect(content, contains('visible test'));
      expect(content, isNot(contains('hidden test')));
      expect(content, contains('tests="1"'));
    });

    test('handles all tests being hidden in end-to-end conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test 1","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"hidden test 2","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","hidden":true,"time":200}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      final testResult = parseResult.valueOrNull!;
      expect(testResult.totalTests, equals(0));
      expect(testResult.suites.isEmpty, isTrue);

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(testResult);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      // Empty test suites should still produce valid XML (may be self-closing tag)
      expect(content, contains('testsuites'));
      // When all tests are hidden, XML may have tests="0" attribute or be empty
      // The XML is valid either way
    });

    test('handles error events in end-to-end conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Expected: true\\nActual: false","stackTrace":"at test/example_test.dart:10","isFailure":true,"time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      final testResult = parseResult.valueOrNull!;
      expect(testResult.totalFailures, equals(1));
      final testCase = testResult.suites.first.testCases.first;
      expect(testCase.status, equals(TestStatus.failed));
      expect(testCase.errorMessage, equals('Expected: true\nActual: false'));
      expect(testCase.stackTrace, equals('at test/example_test.dart:10'));

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(testResult);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      expect(content, contains('<failure'));
      expect(content, contains('Expected: true'));
      expect(content, contains('Actual: false'));
    });

    test('handles multiple tests with error events in end-to-end conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test 1","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error 1","stackTrace":"at test1:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
{"type":"testStart","test":{"id":2,"name":"test 2","suiteID":0},"time":100}
{"type":"error","testID":2,"error":"Error 2","stackTrace":"at test2:20","time":150}
{"type":"testDone","testID":2,"result":"failure","time":200}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      final testResult = parseResult.valueOrNull!;
      expect(testResult.totalFailures, equals(2));
      expect(testResult.suites.first.testCases.length, equals(2));
      expect(testResult.suites.first.testCases[0].errorMessage, equals('Error 1'));
      expect(testResult.suites.first.testCases[1].errorMessage, equals('Error 2'));

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(testResult);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      expect(content, contains('test 1'));
      expect(content, contains('test 2'));
      expect(content, contains('Error 1'));
      expect(content, contains('Error 2'));
    });

    test('testDone error field takes priority over error event in end-to-end conversion', () async {
      final inputFile = File('${tempDir.path}/input.json');
      const inputJson = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error from error event","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","error":"Error from testDone","stackTrace":"at test:20","time":100}
{"type":"done"}
''';
      await inputFile.writeAsString(inputJson);

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      final testResult = parseResult.valueOrNull!;
      final testCase = testResult.suites.first.testCases.first;
      expect(testCase.errorMessage, equals('Error from testDone'));
      expect(testCase.stackTrace, equals('at test:20'));

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(testResult);

      final outputFile = File('${tempDir.path}/output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      final content = await outputFile.readAsString();
      expect(content, contains('Error from testDone'));
      expect(content, isNot(contains('Error from error event')));
    });
  });
}
