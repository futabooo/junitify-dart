import 'dart:convert';
import 'dart:io';

import '../common/error.dart';
import '../common/result.dart';
import '../error/error_reporter.dart';
import '../models/dart_test_result.dart';
import '../models/test_case.dart';
import '../models/test_status.dart';
import '../models/test_suite.dart';

/// Interface for parsing Dart test JSON output.
abstract class DartTestParser {
  /// Parses a JSON string into a DartTestResult.
  ///
  /// [errorReporter] is optional and used for debug logging when hidden tests are detected.
  Result<DartTestResult, ParseError> parse(
    String jsonString, {
    ErrorReporter? errorReporter,
  });
}

/// Default implementation of DartTestParser.
class DefaultDartTestParser implements DartTestParser {
  const DefaultDartTestParser();

  @override
  Result<DartTestResult, ParseError> parse(
    String jsonString, {
    ErrorReporter? errorReporter,
  }) {
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
      return _parseEvents(events, errorReporter);
    } catch (e) {
      return Failure(JsonSyntaxError('Unexpected error: $e'));
    }
  }

  Result<DartTestResult, ParseError> _parseEvents(
    List<Map<String, dynamic>> events,
    ErrorReporter? errorReporter,
  ) {
    try {
      final suites = <String, _SuiteBuilder>{};
      final tests = <int, _TestInfo>{};
      // Map to store print messages grouped by testID
      final printMessages = <int, StringBuffer>{};

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
            _processTestDoneEvent(
              event,
              tests,
              suites,
              errorReporter,
              printMessages,
            );
            break;
          case 'done':
            // Test run completed
            break;
          case 'error':
            // Global error event
            break;
          case 'print':
            _processPrintEvent(event, printMessages);
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

    // Skip if testInfo already exists (use first event's information)
    if (tests.containsKey(id)) {
      return;
    }

    final suite = suites.values.firstWhere(
      (s) => s.id == suiteID,
      orElse: () => _SuiteBuilder(name: 'unknown', id: suiteID),
    );

    // Extract file and line from testStart event
    final url = test['url'] as String?;
    final file = _extractFilePathFromUrl(url);
    final line = _extractLineNumber(test['line']);

    tests[id] = _TestInfo(
      id: id,
      name: name,
      suiteName: suite.name,
      startTime: event['time'] as int? ?? 0,
      file: file,
      line: line,
    );
  }

  /// Extracts a file path from a URL string.
  ///
  /// Converts `file://` URI format to a file path.
  /// Returns null if the URL is not a `file://` URI or is invalid.
  ///
  /// Examples:
  ///   - `file:///home/user/project/test.dart` → `/home/user/project/test.dart`
  ///   - `file:///C:/Users/project/test.dart` → `C:/Users/project/test.dart` (Windows)
  ///   - `http://example.com/test.dart` → null
  ///   - `null` → null
  ///   - `""` → null
  String? _extractFilePathFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Only process file:// URIs
    if (!url.startsWith('file://')) {
      return null;
    }

    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'file') {
        return null;
      }

      // Get the file path from URI
      final path = uri.toFilePath(windows: Platform.isWindows);

      // Try to convert absolute path to relative path if possible
      // For now, we'll return the absolute path as-is
      // Future enhancement: convert to relative path based on current working directory
      return path;
    } catch (e) {
      // If URI parsing fails, return null
      return null;
    }
  }

  /// Extracts a line number from a dynamic value.
  ///
  /// Converts various types to an integer line number.
  /// Returns null if the value is invalid (negative, non-numeric, etc.).
  ///
  /// Examples:
  ///   - `28` → `28`
  ///   - `"28"` → `28`
  ///   - `0` → `0` (valid, as per requirement 5.4)
  ///   - `-1` → `null` (invalid, negative)
  ///   - `null` → `null`
  ///   - `true` → `null` (invalid type)
  int? _extractLineNumber(dynamic lineValue) {
    if (lineValue == null) {
      return null;
    }

    // Handle integer directly
    if (lineValue is int) {
      // Allow 0 as valid value (requirement 5.4)
      return lineValue >= 0 ? lineValue : null;
    }

    // Handle string that contains a number
    if (lineValue is String) {
      if (lineValue.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(lineValue);
      return parsed != null && parsed >= 0 ? parsed : null;
    }

    // Invalid type
    return null;
  }

  void _processPrintEvent(
    Map<String, dynamic> event,
    Map<int, StringBuffer> printMessages,
  ) {
    final testID = event['testID'] as int?;
    if (testID == null) return;

    final message = event['message'] as String?;
    final messageType = event['messageType'] as String?;

    // Only process standard output (ignore stderr/error)
    final isErrorOutput = messageType == 'stderr' || messageType == 'error';
    if (isErrorOutput) return;

    // Get or create StringBuffer for this testID
    final buffer = printMessages.putIfAbsent(testID, () => StringBuffer());

    // If message is null or empty, treat as newline
    if (message == null || message.isEmpty) {
      buffer.write('\n');
    } else {
      // Write message and ensure it ends with a newline
      buffer.write(message);
      // Add newline if message doesn't already end with one
      if (!message.endsWith('\n')) {
        buffer.write('\n');
      }
    }
  }

  void _processTestDoneEvent(
    Map<String, dynamic> event,
    Map<int, _TestInfo> tests,
    Map<String, _SuiteBuilder> suites,
    ErrorReporter? errorReporter,
    Map<int, StringBuffer> printMessages,
  ) {
    final testID = event['testID'] as int?;
    if (testID == null) return;

    final testInfo = tests[testID];
    if (testInfo == null) return;

    final result = event['result'] as String?;
    final skipped = event['skipped'] as bool? ?? false;
    // Handle hidden flag: check if it's a boolean, default to false if not
    final hiddenValue = event['hidden'];
    final hidden = hiddenValue is bool ? hiddenValue : false;
    final time = event['time'] as int? ?? 0;
    final error = event['error'] as String?;
    final stackTrace = event['stackTrace'] as String?;

    // If hidden is true, skip test case creation completely
    if (hidden) {
      if (errorReporter != null) {
        errorReporter.debug(
          'Ignoring hidden test: ${testInfo.suiteName}::${testInfo.name}',
        );
      }
      // Clean up print messages for hidden test
      printMessages.remove(testID);
      return;
    }

    // Determine status
    TestStatus status;
    if (skipped) {
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

    // Get print messages for this test case
    final printBuffer = printMessages.remove(testID);
    final systemOut = printBuffer?.toString();

    // Create test case
    final testCase = TestCase(
      name: testInfo.name,
      className: testInfo.suiteName,
      status: status,
      time: duration,
      errorMessage: error,
      stackTrace: stackTrace,
      systemOut: systemOut,
      file: testInfo.file,
      line: testInfo.line,
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

    // Allow empty test suites (e.g., when all tests are hidden)
    // This is valid according to requirement 3.5
    if (testSuites.isEmpty) {
      // Return an empty result instead of an error
      final emptyResult = DartTestResult(
        suites: [],
        totalTests: 0,
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: Duration.zero,
      );
      return Success(emptyResult);
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
    this.file,
    this.line,
  });

  final int id;
  final String name;
  final String suiteName;
  final int startTime;
  final String? file;
  final int? line;
}
