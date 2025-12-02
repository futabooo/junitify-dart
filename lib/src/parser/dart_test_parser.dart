import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
  /// [fileRelativeTo] is optional and specifies the base directory for converting absolute paths
  /// to relative paths in the file attribute. If null or empty, absolute paths are maintained.
  /// Defaults to null for backward compatibility.
  Result<DartTestResult, ParseError> parse(
    String jsonString, {
    ErrorReporter? errorReporter,
    String? fileRelativeTo,
  });
}

/// Default implementation of DartTestParser.
class DefaultDartTestParser implements DartTestParser {
  const DefaultDartTestParser();

  @override
  Result<DartTestResult, ParseError> parse(
    String jsonString, {
    ErrorReporter? errorReporter,
    String? fileRelativeTo,
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
      return _parseEvents(events, errorReporter, fileRelativeTo);
    } catch (e) {
      return Failure(JsonSyntaxError('Unexpected error: $e'));
    }
  }

  Result<DartTestResult, ParseError> _parseEvents(
    List<Map<String, dynamic>> events,
    ErrorReporter? errorReporter,
    String? fileRelativeTo,
  ) {
    try {
      final suites = <String, _SuiteBuilder>{};
      final tests = <int, _TestInfo>{};
      // Map to store print messages grouped by testID
      final printMessages = <int, StringBuffer>{};
      // Map to store error information grouped by testID
      final testErrors = <int, Map<String, String?>>{};

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
            _processTestStartEvent(event, tests, suites, fileRelativeTo);
            break;
          case 'testDone':
            _processTestDoneEvent(
              event,
              tests,
              suites,
              errorReporter,
              printMessages,
              testErrors,
            );
            break;
          case 'done':
            // Test run completed
            break;
          case 'error':
            _processErrorEvent(event, testErrors);
            break;
          case 'print':
            _processPrintEvent(event, printMessages, tests, suites);
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
    String? fileRelativeTo,
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
    final file = _extractFilePathFromUrl(url, fileRelativeTo);
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
  /// If [fileRelativeTo] is specified (not null and not empty), converts the absolute path
  /// to a relative path using `path.relative`.
  /// Returns null if the URL is not a `file://` URI or is invalid.
  ///
  /// Examples:
  ///   - `file:///home/user/project/test.dart` → `/home/user/project/test.dart` (if fileRelativeTo is null)
  ///   - `file:///home/user/project/test.dart` → `test.dart` (if fileRelativeTo is `/home/user/project`)
  ///   - `file:///C:/Users/project/test.dart` → `C:/Users/project/test.dart` (Windows, if fileRelativeTo is null)
  ///   - `http://example.com/test.dart` → null
  ///   - `null` → null
  ///   - `""` → null
  String? _extractFilePathFromUrl(String? url, String? fileRelativeTo) {
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
      final absolutePath = uri.toFilePath(windows: Platform.isWindows);

      // Convert to relative path if fileRelativeTo is specified
      if (fileRelativeTo != null && fileRelativeTo.isNotEmpty) {
        try {
          return p.relative(absolutePath, from: fileRelativeTo);
        } catch (e) {
          // If conversion fails (e.g., different drives on Windows), return absolute path as fallback
          return absolutePath;
        }
      }

      // Return absolute path if fileRelativeTo is not specified
      return absolutePath;
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
    Map<int, _TestInfo> tests,
    Map<String, _SuiteBuilder> suites,
  ) {
    final testID = event['testID'] as int?;
    final message = event['message'] as String?;
    final messageType = event['messageType'] as String?;

    // Only process standard output (ignore stderr/error)
    final isErrorOutput = messageType == 'stderr' || messageType == 'error';
    if (isErrorOutput) return;

    // If message is null or empty, treat as newline
    final messageToAdd = message ?? '';

    // Determine if this print event is associated with a test case
    final testInfo = testID != null ? tests[testID] : null;
    final isAssociatedWithTestCase = testInfo != null;

    // Process for test case level (existing functionality)
    // Only process if testID exists and test case is found
    if (testID != null && isAssociatedWithTestCase) {
      final buffer = printMessages.putIfAbsent(testID, () => StringBuffer());

      if (messageToAdd.isEmpty) {
        buffer.write('\n');
      } else {
        // Write message and ensure it ends with a newline
        buffer.write(messageToAdd);
        // Add newline if message doesn't already end with one
        if (!messageToAdd.endsWith('\n')) {
          buffer.write('\n');
        }
      }
    }

    // Process for test suite level (new functionality)
    // Only process if testID is missing or test case is not found
    if (!isAssociatedWithTestCase) {
      String? suiteName;

      if (testInfo != null) {
        // If testInfo exists, use its suiteName (this case shouldn't happen due to isAssociatedWithTestCase check)
        suiteName = testInfo.suiteName;
      } else if (testID != null) {
        // If testID exists but testInfo not found, we can't determine the suite from testID
        // Use the most recently created suite as a fallback (typically there's only one suite)
        // This handles the case where print event comes before testStart or testID doesn't match
        if (suites.length == 1) {
          suiteName = suites.keys.first;
        } else {
          // Multiple suites exist - can't reliably determine which one
          // Skip suite-level processing
          return;
        }
      } else {
        // If testID is missing, use the most recently created suite as a fallback
        // Typically there's only one suite in the test run
        if (suites.length == 1) {
          suiteName = suites.keys.first;
        } else {
          // Multiple suites exist - can't reliably determine which one
          // Skip suite-level processing
          return;
        }
      }

      final suite = suites[suiteName];
      if (suite != null) {
        // Get or create StringBuffer for this suite
        suite.systemOut ??= StringBuffer();

        // Add message to suite's systemOut
        if (messageToAdd.isEmpty) {
          suite.systemOut!.write('\n');
        } else {
          suite.systemOut!.write(messageToAdd);
          if (!messageToAdd.endsWith('\n')) {
            suite.systemOut!.write('\n');
          }
        }
      }
    }
  }

  void _processErrorEvent(
    Map<String, dynamic> event,
    Map<int, Map<String, String?>> testErrors,
  ) {
    final testID = event['testID'] as int?;
    if (testID == null) return;

    // Extract error field, converting empty strings to null and non-strings to null
    final errorValue = event['error'];
    final error = errorValue is String && errorValue.isNotEmpty
        ? errorValue
        : null;

    // Extract stackTrace field, converting empty strings to null and non-strings to null
    final stackTraceValue = event['stackTrace'];
    final stackTrace = stackTraceValue is String && stackTraceValue.isNotEmpty
        ? stackTraceValue
        : null;

    // Store error information for this testID
    testErrors[testID] = {'error': error, 'stackTrace': stackTrace};
  }

  void _processTestDoneEvent(
    Map<String, dynamic> event,
    Map<int, _TestInfo> tests,
    Map<String, _SuiteBuilder> suites,
    ErrorReporter? errorReporter,
    Map<int, StringBuffer> printMessages,
    Map<int, Map<String, String?>> testErrors,
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

    // Get error information from testDone event or from error event
    final errorFromDone = event['error'] as String?;
    final stackTraceFromDone = event['stackTrace'] as String?;
    final errorInfo = testErrors[testID];
    final error = errorFromDone ?? errorInfo?['error'];
    final stackTrace = stackTraceFromDone ?? errorInfo?['stackTrace'];

    // Clean up error info after use
    testErrors.remove(testID);

    // If hidden is true, skip test case creation completely
    if (hidden) {
      if (errorReporter != null) {
        errorReporter.debug(
          'Ignoring hidden test: ${testInfo.suiteName}::${testInfo.name}',
        );
      }
      // For hidden tests, move print messages to suite level before removing
      final printBuffer = printMessages.remove(testID);
      if (printBuffer != null && printBuffer.isNotEmpty) {
        final suite = suites[testInfo.suiteName];
        if (suite != null) {
          suite.systemOut ??= StringBuffer();
          suite.systemOut!.write(printBuffer.toString());
        }
      }
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
    // Ensure duration is non-negative (handle edge cases where time might be less than startTime)
    final durationMs = time - testInfo.startTime;
    final duration = Duration(milliseconds: durationMs >= 0 ? durationMs : 0);

    // Get print messages for this test case
    // Remove trailing newline to match tests_report_4.xml format
    final printBuffer = printMessages.remove(testID);
    final systemOutString = printBuffer?.toString();
    final systemOut = systemOutString != null && systemOutString.endsWith('\n')
        ? systemOutString.substring(0, systemOutString.length - 1)
        : systemOutString;

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

      // Convert systemOut StringBuffer to String if not null
      // Remove trailing newline to match tests_report_4.xml format
      final systemOutString = builder.systemOut?.toString();
      final systemOut =
          systemOutString != null && systemOutString.endsWith('\n')
          ? systemOutString.substring(0, systemOutString.length - 1)
          : systemOutString;

      final testSuite = TestSuite(
        name: builder.name,
        testCases: builder.testCases,
        time: suiteTime,
        systemOut: systemOut,
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
      // Debug: Check which validation failed
      final actualTests = result.suites.fold<int>(
        0,
        (sum, suite) => sum + suite.totalTests,
      );
      final actualFailures = result.suites.fold<int>(
        0,
        (sum, suite) => sum + suite.totalFailures + suite.totalErrors,
      );
      final actualSkipped = result.suites.fold<int>(
        0,
        (sum, suite) => sum + suite.totalSkipped,
      );

      String reason = 'Invalid test result data';
      if (result.totalTests != actualTests) {
        reason =
            'totalTests mismatch: expected ${result.totalTests}, got $actualTests';
      } else if (result.totalFailures != actualFailures) {
        reason =
            'totalFailures mismatch: expected ${result.totalFailures}, got $actualFailures';
      } else if (result.totalSkipped != actualSkipped) {
        reason =
            'totalSkipped mismatch: expected ${result.totalSkipped}, got $actualSkipped';
      } else if (result.totalTime.isNegative) {
        reason = 'totalTime is negative: ${result.totalTime.inMilliseconds}ms';
      } else {
        // Check for negative durations or invalid test cases
        for (final suite in result.suites) {
          if (suite.time.isNegative) {
            reason =
                'Suite time is negative: ${suite.name} has ${suite.time.inMilliseconds}ms';
            break;
          }
          for (final testCase in suite.testCases) {
            if (testCase.time.isNegative) {
              reason =
                  'Test case time is negative: ${testCase.name} has ${testCase.time.inMilliseconds}ms';
              break;
            }
            if (!testCase.isValid) {
              reason =
                  'Test case is invalid: ${testCase.name} (status: ${testCase.status}, hasError: ${testCase.hasError}, errorMessage: ${testCase.errorMessage})';
              break;
            }
          }
        }
      }

      return Failure(InvalidFormatError('result', reason));
    }

    return Success(result);
  }
}

class _SuiteBuilder {
  _SuiteBuilder({required this.name, required this.id});

  final String name;
  final int id;
  final List<TestCase> testCases = [];
  StringBuffer? systemOut;
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
