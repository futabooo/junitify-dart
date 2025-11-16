import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultDartTestParser', () {
    const parser = DefaultDartTestParser();

    test('parses valid Dart test JSON successfully', () {
      const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"example test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
{"type":"done"}
''';

      final result = parser.parse(json);

      expect(result.isSuccess, isTrue);
      final testResult = result.valueOrNull!;
      expect(testResult.suites.length, equals(1));
      expect(testResult.totalTests, equals(1));
      expect(testResult.suites.first.name, equals('test/example_test.dart'));
    });

    test('handles failed test correctly', () {
      const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"failure","time":100,"error":"Expected: true\\nActual: false","stackTrace":"at test/example_test.dart:10"}
''';

      final result = parser.parse(json);

      expect(result.isSuccess, isTrue);
      final testResult = result.valueOrNull!;
      expect(testResult.totalFailures, equals(1));
      final testCase = testResult.suites.first.testCases.first;
      expect(testCase.status, equals(TestStatus.failed));
      expect(testCase.errorMessage, isNotNull);
      expect(testCase.stackTrace, isNotNull);
    });

    test('handles skipped test correctly', () {
      const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"skipped test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","skipped":true,"time":0}
''';

      final result = parser.parse(json);

      expect(result.isSuccess, isTrue);
      final testResult = result.valueOrNull!;
      expect(testResult.totalSkipped, equals(1));
      final testCase = testResult.suites.first.testCases.first;
      expect(testCase.status, equals(TestStatus.skipped));
    });

    test('returns error for invalid JSON syntax', () {
      const json = '{invalid json}';

      final result = parser.parse(json);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<JsonSyntaxError>());
    });

    test('returns error for empty input', () {
      const json = '';

      final result = parser.parse(json);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<InvalidFormatError>());
    });

    test('handles multiple test suites', () {
      const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/first_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test 1","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":100}
{"type":"suite","suite":{"id":1,"platform":"vm","path":"test/second_test.dart"}}
{"type":"testStart","test":{"id":2,"name":"test 2","suiteID":1},"time":100}
{"type":"testDone","testID":2,"result":"success","time":200}
''';

      final result = parser.parse(json);

      expect(result.isSuccess, isTrue);
      final testResult = result.valueOrNull!;
      expect(testResult.suites.length, equals(2));
      expect(testResult.totalTests, equals(2));
    });

    test('handles error test result', () {
      const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"error test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"error","time":100,"error":"Exception: Something went wrong"}
''';

      final result = parser.parse(json);

      expect(result.isSuccess, isTrue);
      final testResult = result.valueOrNull!;
      final testCase = testResult.suites.first.testCases.first;
      expect(testCase.status, equals(TestStatus.error));
    });
  });
}
