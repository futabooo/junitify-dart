import 'test_status.dart';

/// Represents a single test case execution result.
class TestCase {
  const TestCase({
    required this.name,
    required this.className,
    required this.status,
    required this.time,
    this.errorMessage,
    this.stackTrace,
    this.systemOut,
  });

  /// The name of the test case.
  final String name;

  /// The class name or test file path.
  final String className;

  /// The execution status of the test.
  final TestStatus status;

  /// The execution time in milliseconds.
  final Duration time;

  /// The error message if the test failed or had an error.
  final String? errorMessage;

  /// The stack trace if the test failed or had an error.
  final String? stackTrace;

  /// Standard output from all print events in this test case.
  /// Contains all print outputs joined by newlines in chronological order.
  final String? systemOut;

  /// Returns true if this test case failed or had an error.
  bool get hasError =>
      status == TestStatus.failed || status == TestStatus.error;

  /// Validates that error message is present when test failed or had error.
  bool get isValid {
    if (hasError && (errorMessage == null || errorMessage!.isEmpty)) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCase &&
          name == other.name &&
          className == other.className &&
          status == other.status &&
          time == other.time &&
          errorMessage == other.errorMessage &&
          stackTrace == other.stackTrace &&
          systemOut == other.systemOut;

  @override
  int get hashCode =>
      Object.hash(name, className, status, time, errorMessage, stackTrace, systemOut);

  @override
  String toString() =>
      'TestCase('
      'name: $name, '
      'className: $className, '
      'status: $status, '
      'time: ${time.inMilliseconds}ms'
      ')';
}
