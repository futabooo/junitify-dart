import 'test_suite.dart';

/// Represents the complete result of a Dart test execution.
class DartTestResult {
  const DartTestResult({
    required this.suites,
    required this.totalTests,
    required this.totalFailures,
    required this.totalSkipped,
    required this.totalTime,
  });

  /// All test suites in the result.
  final List<TestSuite> suites;

  /// The total number of test cases across all suites.
  final int totalTests;

  /// The total number of failures across all suites.
  final int totalFailures;

  /// The total number of skipped tests across all suites.
  final int totalSkipped;

  /// The total execution time across all suites.
  final Duration totalTime;

  /// Validates the invariants of this result.
  ///
  /// Returns true if:
  /// - totalTests equals the sum of all test cases
  /// - totalFailures equals the count of failed and errored tests
  /// - totalSkipped equals the count of skipped tests
  /// - all durations are non-negative
  bool get isValid {
    // Count actual tests
    final actualTests = suites.fold<int>(
      0,
      (sum, suite) => sum + suite.totalTests,
    );

    if (totalTests != actualTests) {
      return false;
    }

    // Count actual failures (failed + error)
    final actualFailures = suites.fold<int>(
      0,
      (sum, suite) => sum + suite.totalFailures + suite.totalErrors,
    );

    if (totalFailures != actualFailures) {
      return false;
    }

    // Count actual skipped
    final actualSkipped = suites.fold<int>(
      0,
      (sum, suite) => sum + suite.totalSkipped,
    );

    if (totalSkipped != actualSkipped) {
      return false;
    }

    // Validate non-negative durations
    if (totalTime.isNegative) {
      return false;
    }

    for (final suite in suites) {
      if (suite.time.isNegative) {
        return false;
      }
      for (final testCase in suite.testCases) {
        if (testCase.time.isNegative) {
          return false;
        }
        // Validate test case invariants
        if (!testCase.isValid) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartTestResult &&
          _listEquals(suites, other.suites) &&
          totalTests == other.totalTests &&
          totalFailures == other.totalFailures &&
          totalSkipped == other.totalSkipped &&
          totalTime == other.totalTime;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(suites),
    totalTests,
    totalFailures,
    totalSkipped,
    totalTime,
  );

  @override
  String toString() =>
      'DartTestResult('
      'suites: ${suites.length}, '
      'tests: $totalTests, '
      'failures: $totalFailures, '
      'skipped: $totalSkipped, '
      'time: ${totalTime.inMilliseconds}ms'
      ')';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
