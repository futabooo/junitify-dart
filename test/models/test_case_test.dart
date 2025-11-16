import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('TestCase', () {
    test('hasError returns true for failed status', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.failed,
        time: Duration(milliseconds: 100),
        errorMessage: 'Test failed',
      );

      expect(testCase.hasError, isTrue);
    });

    test('hasError returns true for error status', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.error,
        time: Duration(milliseconds: 100),
        errorMessage: 'Error occurred',
      );

      expect(testCase.hasError, isTrue);
    });

    test('hasError returns false for passed status', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.passed,
        time: Duration(milliseconds: 100),
      );

      expect(testCase.hasError, isFalse);
    });

    test('hasError returns false for skipped status', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.skipped,
        time: Duration(milliseconds: 100),
      );

      expect(testCase.hasError, isFalse);
    });

    test('isValid returns false when failed test has no error message', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.failed,
        time: Duration(milliseconds: 100),
      );

      expect(testCase.isValid, isFalse);
    });

    test('isValid returns false when error test has empty error message', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.error,
        time: Duration(milliseconds: 100),
        errorMessage: '',
      );

      expect(testCase.isValid, isFalse);
    });

    test('isValid returns true when failed test has error message', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.failed,
        time: Duration(milliseconds: 100),
        errorMessage: 'Test failed',
      );

      expect(testCase.isValid, isTrue);
    });

    test('isValid returns true for passed test without error message', () {
      const testCase = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.passed,
        time: Duration(milliseconds: 100),
      );

      expect(testCase.isValid, isTrue);
    });

    test('equality works correctly', () {
      const testCase1 = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.passed,
        time: Duration(milliseconds: 100),
      );

      const testCase2 = TestCase(
        name: 'test1',
        className: 'TestClass',
        status: TestStatus.passed,
        time: Duration(milliseconds: 100),
      );

      expect(testCase1, equals(testCase2));
    });
  });
}
