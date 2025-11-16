import 'dart:convert';

import '../common/error.dart';
import '../common/result.dart';
import '../models/dart_test_result.dart';
import '../models/test_case.dart';
import '../models/test_status.dart';
import '../models/test_suite.dart';

/// Interface for parsing Dart test JSON output.
abstract class DartTestParser {
  /// Parses a JSON string into a DartTestResult.
  Result<DartTestResult, ParseError> parse(String jsonString);
}

/// Default implementation of DartTestParser.
class DefaultDartTestParser implements DartTestParser {
  const DefaultDartTestParser();

  @override
  Result<DartTestResult, ParseError> parse(String jsonString) {
    try {
      // Parse JSON lines (Dart test outputs newline-delimited JSON)
      final lines = jsonString.trim().split('\n');
      final events = <Map<String, dynamic>>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          final event = jsonDecode(line) as Map<String, dynamic>;
          events.add(event);
        } on FormatException catch (e) {
          return Failure(JsonSyntaxError(e.message));
        } catch (e) {
          return Failure(JsonSyntaxError('Invalid JSON: $e'));
        }
      }

      if (events.isEmpty) {
        return const Failure(
          InvalidFormatError('input', 'No valid JSON events found'),
        );
      }

      // Parse events into test results
      return _parseEvents(events);
    } catch (e) {
      return Failure(JsonSyntaxError('Unexpected error: $e'));
    }
  }

  Result<DartTestResult, ParseError> _parseEvents(
    List<Map<String, dynamic>> events,
  ) {
    try {
      final suites = <String, _SuiteBuilder>{};
      final tests = <int, _TestInfo>{};

      for (final event in events) {
        final type = event['type'] as String?;
        if (type == null) continue;

        switch (type) {
          case 'suite':
            _processSuiteEvent(event, suites);
            break;
          case 'group':
            // Groups are optional, we handle them implicitly
            break;
          case 'testStart':
            _processTestStartEvent(event, tests, suites);
            break;
          case 'testDone':
            _processTestDoneEvent(event, tests, suites);
            break;
          case 'done':
            // Test run completed
            break;
          case 'error':
            // Global error event
            break;
          case 'print':
            // Print output, can be ignored for JUnit conversion
            break;
        }
      }

      // Build final result
      return _buildResult(suites);
    } catch (e) {
      if (e is ParseError) {
        return Failure(e);
      }
      return Failure(InvalidFormatError('events', 'Failed to parse: $e'));
    }
  }

  void _processSuiteEvent(
    Map<String, dynamic> event,
    Map<String, _SuiteBuilder> suites,
  ) {
    final suite = event['suite'] as Map<String, dynamic>?;
    if (suite == null) {
      throw const MissingFieldError('suite');
    }

    final id = suite['id'] as int?;
    final path = suite['path'] as String?;

    if (id == null) {
      throw const MissingFieldError('suite.id');
    }

    final suiteName = path ?? 'test_suite_$id';
    suites[suiteName] = _SuiteBuilder(name: suiteName, id: id);
  }

  void _processTestStartEvent(
    Map<String, dynamic> event,
    Map<int, _TestInfo> tests,
    Map<String, _SuiteBuilder> suites,
  ) {
    final test = event['test'] as Map<String, dynamic>?;
    if (test == null) return;

    final id = test['id'] as int?;
    final name = test['name'] as String?;
    final suiteID = test['suiteID'] as int?;

    if (id == null || name == null || suiteID == null) {
      return;
    }

    final suite = suites.values.firstWhere(
      (s) => s.id == suiteID,
      orElse: () => _SuiteBuilder(name: 'unknown', id: suiteID),
    );

    tests[id] = _TestInfo(
      id: id,
      name: name,
      suiteName: suite.name,
      startTime: event['time'] as int? ?? 0,
    );
  }

  void _processTestDoneEvent(
    Map<String, dynamic> event,
    Map<int, _TestInfo> tests,
    Map<String, _SuiteBuilder> suites,
  ) {
    final testID = event['testID'] as int?;
    if (testID == null) return;

    final testInfo = tests[testID];
    if (testInfo == null) return;

    final result = event['result'] as String?;
    final skipped = event['skipped'] as bool? ?? false;
    final hidden = event['hidden'] as bool? ?? false;
    final time = event['time'] as int? ?? 0;
    final error = event['error'] as String?;
    final stackTrace = event['stackTrace'] as String?;

    // Determine status
    TestStatus status;
    if (skipped || hidden) {
      status = TestStatus.skipped;
    } else if (result == 'success') {
      status = TestStatus.passed;
    } else if (result == 'failure') {
      status = TestStatus.failed;
    } else if (result == 'error') {
      status = TestStatus.error;
    } else {
      status = TestStatus.error;
    }

    // Calculate duration
    final duration = Duration(milliseconds: time - testInfo.startTime);

    // Create test case
    final testCase = TestCase(
      name: testInfo.name,
      className: testInfo.suiteName,
      status: status,
      time: duration,
      errorMessage: error,
      stackTrace: stackTrace,
    );

    // Add to suite
    final suite = suites[testInfo.suiteName];
    if (suite != null) {
      suite.testCases.add(testCase);
    }
  }

  Result<DartTestResult, ParseError> _buildResult(
    Map<String, _SuiteBuilder> suites,
  ) {
    final testSuites = <TestSuite>[];
    var totalTests = 0;
    var totalFailures = 0;
    var totalSkipped = 0;
    var totalTime = Duration.zero;

    for (final builder in suites.values) {
      if (builder.testCases.isEmpty) continue;

      // Calculate suite time
      final suiteTime = builder.testCases.fold<Duration>(
        Duration.zero,
        (sum, test) => sum + test.time,
      );

      final testSuite = TestSuite(
        name: builder.name,
        testCases: builder.testCases,
        time: suiteTime,
      );

      testSuites.add(testSuite);

      totalTests += testSuite.totalTests;
      totalFailures += testSuite.totalFailures + testSuite.totalErrors;
      totalSkipped += testSuite.totalSkipped;
      totalTime += suiteTime;
    }

    if (testSuites.isEmpty) {
      return const Failure(InvalidFormatError('tests', 'No test cases found'));
    }

    final result = DartTestResult(
      suites: testSuites,
      totalTests: totalTests,
      totalFailures: totalFailures,
      totalSkipped: totalSkipped,
      totalTime: totalTime,
    );

    if (!result.isValid) {
      return const Failure(
        InvalidFormatError('result', 'Invalid test result data'),
      );
    }

    return Success(result);
  }
}

class _SuiteBuilder {
  _SuiteBuilder({required this.name, required this.id});

  final String name;
  final int id;
  final List<TestCase> testCases = [];
}

class _TestInfo {
  _TestInfo({
    required this.id,
    required this.name,
    required this.suiteName,
    required this.startTime,
  });

  final int id;
  final String name;
  final String suiteName;
  final int startTime;
}
