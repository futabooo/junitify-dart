import 'test_case.dart';
import 'test_status.dart';

/// Represents a test suite containing multiple test cases.
class TestSuite {
  const TestSuite({
    required this.name,
    required this.testCases,
    required this.time,
    this.systemOut,
  });

  /// The name of the test suite (usually file path).
  final String name;

  /// All test cases in this suite.
  final List<TestCase> testCases;

  /// The total execution time for this suite.
  final Duration time;

  /// Standard output from all print events in this test suite.
  /// Contains all print outputs joined by newlines in chronological order.
  final String? systemOut;

  /// Returns the number of tests in this suite.
  int get totalTests => testCases.length;

  /// Returns the number of failed tests.
  int get totalFailures =>
      testCases.where((test) => test.status == TestStatus.failed).length;

  /// Returns the number of tests with errors.
  int get totalErrors =>
      testCases.where((test) => test.status == TestStatus.error).length;

  /// Returns the number of skipped tests.
  int get totalSkipped =>
      testCases.where((test) => test.status == TestStatus.skipped).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSuite &&
          name == other.name &&
          _listEquals(testCases, other.testCases) &&
          time == other.time &&
          systemOut == other.systemOut;

  @override
  int get hashCode =>
      Object.hash(name, Object.hashAll(testCases), time, systemOut);

  @override
  String toString() =>
      'TestSuite('
      'name: $name, '
      'tests: $totalTests, '
      'failures: $totalFailures, '
      'errors: $totalErrors, '
      'skipped: $totalSkipped'
      ')';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
