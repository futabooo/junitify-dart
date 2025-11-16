/// The status of a test case execution.
enum TestStatus {
  /// The test passed successfully.
  passed,

  /// The test failed.
  failed,

  /// The test was skipped.
  skipped,

  /// An error occurred during test execution.
  error,
}
