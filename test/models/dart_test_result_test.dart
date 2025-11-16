import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('DartTestResult', () {
    test('isValid returns true for valid result', () {
      final result = DartTestResult(
        suites: [
          TestSuite(
            name: 'suite1',
            testCases: const [
              TestCase(
                name: 'test1',
                className: 'TestClass',
                status: TestStatus.passed,
                time: Duration(milliseconds: 100),
              ),
              TestCase(
                name: 'test2',
                className: 'TestClass',
                status: TestStatus.failed,
                time: Duration(milliseconds: 200),
                errorMessage: 'Failed',
              ),
            ],
            time: const Duration(milliseconds: 300),
          ),
        ],
        totalTests: 2,
        totalFailures: 1,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 300),
      );

      expect(result.isValid, isTrue);
    });

    test('isValid returns false when totalTests does not match', () {
      final result = DartTestResult(
        suites: [
          TestSuite(
            name: 'suite1',
            testCases: const [
              TestCase(
                name: 'test1',
                className: 'TestClass',
                status: TestStatus.passed,
                time: Duration(milliseconds: 100),
              ),
            ],
            time: const Duration(milliseconds: 100),
          ),
        ],
        totalTests: 3, // Wrong count
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 100),
      );

      expect(result.isValid, isFalse);
    });

    test('isValid returns false when totalFailures does not match', () {
      final result = DartTestResult(
        suites: [
          TestSuite(
            name: 'suite1',
            testCases: const [
              TestCase(
                name: 'test1',
                className: 'TestClass',
                status: TestStatus.failed,
                time: Duration(milliseconds: 100),
                errorMessage: 'Failed',
              ),
            ],
            time: const Duration(milliseconds: 100),
          ),
        ],
        totalTests: 1,
        totalFailures: 0, // Wrong count
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 100),
      );

      expect(result.isValid, isFalse);
    });

    test('isValid returns false for negative duration', () {
      final result = DartTestResult(
        suites: [
          TestSuite(
            name: 'suite1',
            testCases: const [
              TestCase(
                name: 'test1',
                className: 'TestClass',
                status: TestStatus.passed,
                time: Duration(milliseconds: 100),
              ),
            ],
            time: const Duration(milliseconds: 100),
          ),
        ],
        totalTests: 1,
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: -100), // Negative
      );

      expect(result.isValid, isFalse);
    });

    test('isValid returns false when test case is invalid', () {
      final result = DartTestResult(
        suites: [
          TestSuite(
            name: 'suite1',
            testCases: const [
              TestCase(
                name: 'test1',
                className: 'TestClass',
                status: TestStatus.failed,
                time: Duration(milliseconds: 100),
                // Missing error message - invalid
              ),
            ],
            time: const Duration(milliseconds: 100),
          ),
        ],
        totalTests: 1,
        totalFailures: 1,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 100),
      );

      expect(result.isValid, isFalse);
    });
  });
}
