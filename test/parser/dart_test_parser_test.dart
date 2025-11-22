import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

// Mock ErrorReporter for testing
class _MockErrorReporter implements ErrorReporter {
  final List<String> debugMessages = [];
  final bool debugMode;

  _MockErrorReporter({this.debugMode = true});

  @override
  void reportError(AppError error, {bool includeStackTrace = false}) {}

  @override
  void debug(String message) {
    if (debugMode) {
      debugMessages.add(message);
    }
  }

  @override
  void info(String message) {}
}

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

    group('hidden flag support', () {
      test('excludes test case when hidden is true', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":150}
{"type":"testStart","test":{"id":2,"name":"visible test","suiteID":0},"time":150}
{"type":"testDone","testID":2,"result":"success","time":300}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(1));
        expect(testResult.suites.first.testCases.length, equals(1));
        expect(testResult.suites.first.testCases.first.name, equals('visible test'));
      });

    group('print event support', () {
      test('collects print events and adds to test case systemOut', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with output","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"First output line","messageType":"print","time":50}
{"type":"print","testID":1,"message":"Second output line","messageType":"print","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.suites.length, equals(1));
        final suite = testResult.suites.first;
        expect(suite.testCases.length, equals(1));
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, isNotNull);
        expect(testCase.systemOut, equals('First output line\nSecond output line\n'));
        // Suite level systemOut should be null
        expect(suite.systemOut, isNull);
      });

      test('handles empty message in print event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with empty output","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"","messageType":"print","time":50}
{"type":"print","testID":1,"message":"Non-empty line","messageType":"print","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, equals('\nNon-empty line\n'));
      });

      test('ignores print event when testID is missing', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","message":"Output without testID","messageType":"print","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, isNull);
      });

      test('ignores print event when testID does not match any test', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":999,"message":"Output for non-existent test","messageType":"print","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, isNull);
      });

      test('handles missing message field in print event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":1,"messageType":"print","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        // Missing message field is treated as empty string, which becomes a newline
        expect(testCase.systemOut, equals('\n'));
      });

      test('systemOut is null when no print events exist', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test without output","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, isNull);
      });

      test('collects print events from multiple tests in same suite', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test 1","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"Output from test 1","messageType":"print","time":50}
{"type":"testDone","testID":1,"result":"success","time":100}
{"type":"testStart","test":{"id":2,"name":"test 2","suiteID":0},"time":100}
{"type":"print","testID":2,"message":"Output from test 2","messageType":"print","time":150}
{"type":"testDone","testID":2,"result":"success","time":200}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        expect(suite.testCases.length, equals(2));
        expect(suite.testCases[0].systemOut, equals('Output from test 1\n'));
        expect(suite.testCases[1].systemOut, equals('Output from test 2\n'));
        // Suite level systemOut should be null
        expect(suite.systemOut, isNull);
      });
    });

    group('error output event support', () {
      test('ignores error output events with messageType stderr (system-err not supported)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with error output","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"Error line 1","messageType":"stderr","time":50}
{"type":"print","testID":1,"message":"Error line 2","messageType":"stderr","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.suites.length, equals(1));
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        // system-err is not supported at testcase level, so it should be null
        expect(testCase.systemOut, isNull);
        expect(suite.systemErr, isNull);
      });

      test('ignores error output events with messageType error (system-err not supported)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with error output","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"Error message","messageType":"error","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        // system-err is not supported at testcase level, so it should be null
        expect(testCase.systemOut, isNull);
        expect(suite.systemErr, isNull);
      });

      test('ignores error output events (system-err not supported)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with empty error","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"","messageType":"stderr","time":50}
{"type":"print","testID":1,"message":"Non-empty error","messageType":"stderr","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        // system-err is not supported at testcase level, so it should be null
        expect(testCase.systemOut, isNull);
        expect(suite.systemErr, isNull);
      });

      test('ignores error output event when testID is missing', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","message":"Error without testID","messageType":"stderr","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        expect(suite.systemErr, isNull);
      });

      test('ignores error output event when testID does not match any test', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":999,"message":"Error for non-existent test","messageType":"stderr","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        expect(suite.systemErr, isNull);
      });

      test('ignores error output events with missing message (system-err not supported)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":1,"messageType":"stderr","time":50}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        // system-err is not supported at testcase level, so it should be null
        expect(testCase.systemOut, isNull);
        expect(suite.systemErr, isNull);
      });

      test('systemErr is null when no error output events exist', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test without error output","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        expect(suite.systemErr, isNull);
      });

      test('processes print events as systemOut when messageType is print or null', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"Output line","messageType":"print","time":50}
{"type":"print","testID":1,"message":"Another output","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, isNotNull);
        expect(testCase.systemOut, contains('Output line'));
        expect(testCase.systemOut, contains('Another output'));
        expect(suite.systemOut, isNull);
        expect(suite.systemErr, isNull);
      });

      test('collects systemOut but ignores systemErr (system-err not supported)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"print","testID":1,"message":"Output line","messageType":"print","time":50}
{"type":"print","testID":1,"message":"Error line","messageType":"stderr","time":100}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final suite = testResult.suites.first;
        final testCase = suite.testCases.first;
        expect(testCase.systemOut, equals('Output line\n'));
        // system-err is not supported at testcase level
        expect(suite.systemErr, isNull);
      });
    });

      test('processes test case normally when hidden is false', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"visible test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":false,"time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(1));
        expect(testResult.suites.first.testCases.length, equals(1));
      });

      test('processes test case normally when hidden is not specified', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"normal test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(1));
        expect(testResult.suites.first.testCases.length, equals(1));
      });

      test('treats non-boolean hidden value as false', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test with string hidden","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":"true","time":150}
{"type":"testStart","test":{"id":2,"name":"test with number hidden","suiteID":0},"time":150}
{"type":"testDone","testID":2,"result":"success","hidden":1,"time":300}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        // Both tests should be processed (non-boolean values treated as false)
        expect(testResult.totalTests, equals(2));
      });

      test('hidden flag takes priority over skipped flag', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden and skipped test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"skipped":true,"time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        // Test should be completely excluded, not counted as skipped
        expect(testResult.totalTests, equals(0));
        expect(testResult.totalSkipped, equals(0));
        expect(testResult.suites.isEmpty, isTrue);
      });

      test('outputs debug log when hidden test is detected and errorReporter is provided', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":150}
''';

        final errorReporter = _MockErrorReporter(debugMode: true);
        final result = parser.parse(json, errorReporter: errorReporter);

        expect(result.isSuccess, isTrue);
        expect(errorReporter.debugMessages.length, equals(1));
        expect(
          errorReporter.debugMessages.first,
          equals('Ignoring hidden test: test/example_test.dart::hidden test'),
        );
      });

      test('does not output debug log when debugMode is false', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":150}
''';

        final errorReporter = _MockErrorReporter(debugMode: false);
        final result = parser.parse(json, errorReporter: errorReporter);

        expect(result.isSuccess, isTrue);
        expect(errorReporter.debugMessages.isEmpty, isTrue);
      });

      test('does not output debug log when errorReporter is not provided', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        // No error should occur when errorReporter is null
      });

      test('excludes hidden tests from statistics', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden passed","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"hidden failed","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"failure","hidden":true,"time":200,"error":"Failed"}
{"type":"testStart","test":{"id":3,"name":"visible passed","suiteID":0},"time":200}
{"type":"testDone","testID":3,"result":"success","time":300}
{"type":"testStart","test":{"id":4,"name":"visible failed","suiteID":0},"time":300}
{"type":"testDone","testID":4,"result":"failure","time":400,"error":"Failed"}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(2)); // Only visible tests
        expect(testResult.totalFailures, equals(1)); // Only visible failed test
        expect(testResult.totalSkipped, equals(0));
      });

      test('handles all tests being hidden by returning empty result', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"hidden test 1","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","hidden":true,"time":100}
{"type":"testStart","test":{"id":2,"name":"hidden test 2","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","hidden":true,"time":200}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(0));
        expect(testResult.suites.isEmpty, isTrue);
        expect(testResult.totalFailures, equals(0));
        expect(testResult.totalSkipped, equals(0));
        expect(testResult.totalTime, equals(Duration.zero));
      });
    });

    group('error event support', () {
      test('processes error event and sets error info on test case', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Expected: true\\nActual: false","stackTrace":"at test/example_test.dart:10","isFailure":true,"time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalFailures, equals(1));
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Expected: true\nActual: false'));
        expect(testCase.stackTrace, equals('at test/example_test.dart:10'));
      });

      test('ignores error event when testID is missing', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test","suiteID":0},"time":0}
{"type":"error","error":"Some error","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"success","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.passed));
        expect(testCase.errorMessage, isNull);
        expect(testCase.stackTrace, isNull);
      });

      test('handles error event with missing error field', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"stackTrace":"at test/example_test.dart:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        // When error field is missing and testDone has no error field,
        // the test case will be invalid (failed test without error message)
        // This violates TestCase.isValid requirement, so parsing should fail
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<InvalidFormatError>());
      });

      test('handles error event with missing stackTrace field', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Expected: true\\nActual: false","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Expected: true\nActual: false'));
        expect(testCase.stackTrace, isNull);
      });

      test('ignores isFailure field in error event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Test error","stackTrace":"at test:10","isFailure":false,"time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Test error'));
        expect(testCase.stackTrace, equals('at test:10'));
      });

      test('overwrites error info when multiple error events occur for same testID', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"First error","stackTrace":"at test:10","time":50}
{"type":"error","testID":1,"error":"Second error","stackTrace":"at test:20","time":60}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Second error'));
        expect(testCase.stackTrace, equals('at test:20'));
      });

      test('testDone error field takes priority over error event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error from error event","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","error":"Error from testDone","stackTrace":"at test:20","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Error from testDone'));
        expect(testCase.stackTrace, equals('at test:20'));
      });

      test('uses error event info when testDone has no error field', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error from error event","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Error from error event'));
        expect(testCase.stackTrace, equals('at test:10'));
      });

      test('handles multiline error message from error event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Line 1\\nLine 2\\nLine 3","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.errorMessage, equals('Line 1\nLine 2\nLine 3'));
      });

      test('handles multiline stackTrace from error event', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Test error","stackTrace":"Line 1\\nLine 2\\nLine 3","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.stackTrace, equals('Line 1\nLine 2\nLine 3'));
      });

      test('handles error event for error status test', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"error test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Exception: Something went wrong","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"error","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.error));
        expect(testCase.errorMessage, equals('Exception: Something went wrong'));
        expect(testCase.stackTrace, equals('at test:10'));
      });

      test('handles error event before testStart (edge case)', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"error","testID":1,"error":"Error before testStart","stackTrace":"at test:10","time":50}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":100}
{"type":"testDone","testID":1,"result":"failure","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Error before testStart'));
        expect(testCase.stackTrace, equals('at test:10'));
      });

      test('handles empty string error field', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        // Empty string is converted to null, which violates TestCase.isValid requirement
        // for failed tests, so parsing should fail
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<InvalidFormatError>());
      });

      test('handles empty string stackTrace field', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Test error","stackTrace":"","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Test error'));
        // Empty string is converted to null
        expect(testCase.stackTrace, isNull);
      });

      test('handles non-string error field gracefully', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":123,"stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        // Non-string error field is treated as null, which violates TestCase.isValid requirement
        // for failed tests, so parsing should fail
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<InvalidFormatError>());
      });

      test('handles non-string stackTrace field gracefully', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Test error","stackTrace":true,"time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Test error'));
        // Non-string stackTrace field is treated as null
        expect(testCase.stackTrace, isNull);
        // Test case should be valid since it has an error message
        expect(testCase.isValid, isTrue);
      });

      test('maintains backward compatibility when no error events exist', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"failure","error":"Error from testDone","stackTrace":"at test:10","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.failed));
        expect(testCase.errorMessage, equals('Error from testDone'));
        expect(testCase.stackTrace, equals('at test:10'));
      });

      test('maintains backward compatibility for passed tests', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"passing test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.passed));
        expect(testCase.errorMessage, isNull);
        expect(testCase.stackTrace, isNull);
      });

      test('maintains backward compatibility for skipped tests', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"skipped test","suiteID":0},"time":0}
{"type":"testDone","testID":1,"result":"success","skipped":true,"time":100}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        final testCase = testResult.suites.first.testCases.first;
        expect(testCase.status, equals(TestStatus.skipped));
        expect(testCase.errorMessage, isNull);
        expect(testCase.stackTrace, isNull);
      });

      test('handles multiple tests with error events', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"test 1","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error 1","stackTrace":"at test1:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
{"type":"testStart","test":{"id":2,"name":"test 2","suiteID":0},"time":100}
{"type":"error","testID":2,"error":"Error 2","stackTrace":"at test2:20","time":150}
{"type":"testDone","testID":2,"result":"failure","time":200}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalFailures, equals(2));
        expect(testResult.suites.first.testCases.length, equals(2));
        expect(testResult.suites.first.testCases[0].errorMessage, equals('Error 1'));
        expect(testResult.suites.first.testCases[1].errorMessage, equals('Error 2'));
      });

      test('cleans up error info after testDone processing', () {
        const json = '''
{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/example_test.dart"}}
{"type":"testStart","test":{"id":1,"name":"failing test","suiteID":0},"time":0}
{"type":"error","testID":1,"error":"Error message","stackTrace":"at test:10","time":50}
{"type":"testDone","testID":1,"result":"failure","time":100}
{"type":"testStart","test":{"id":2,"name":"another test","suiteID":0},"time":100}
{"type":"testDone","testID":2,"result":"success","time":150}
''';

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        final testResult = result.valueOrNull!;
        expect(testResult.totalTests, equals(2));
        expect(testResult.totalFailures, equals(1));
        // Error info should be cleaned up, so test 2 should not have error info
        expect(testResult.suites.first.testCases[1].errorMessage, isNull);
      });
    });
  });
}
