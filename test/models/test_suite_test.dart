import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('TestSuite', () {
    test('totalTests returns correct count', () {
      final testSuite = TestSuite(
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
            status: TestStatus.passed,
            time: Duration(milliseconds: 200),
          ),
        ],
        time: const Duration(milliseconds: 300),
      );

      expect(testSuite.totalTests, equals(2));
    });

    test('totalFailures returns correct count', () {
      final testSuite = TestSuite(
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
          TestCase(
            name: 'test3',
            className: 'TestClass',
            status: TestStatus.failed,
            time: Duration(milliseconds: 150),
            errorMessage: 'Failed',
          ),
        ],
        time: const Duration(milliseconds: 450),
      );

      expect(testSuite.totalFailures, equals(2));
    });

    test('totalErrors returns correct count', () {
      final testSuite = TestSuite(
        name: 'suite1',
        testCases: const [
          TestCase(
            name: 'test1',
            className: 'TestClass',
            status: TestStatus.error,
            time: Duration(milliseconds: 100),
            errorMessage: 'Error',
          ),
          TestCase(
            name: 'test2',
            className: 'TestClass',
            status: TestStatus.passed,
            time: Duration(milliseconds: 200),
          ),
        ],
        time: const Duration(milliseconds: 300),
      );

      expect(testSuite.totalErrors, equals(1));
    });

    test('totalSkipped returns correct count', () {
      final testSuite = TestSuite(
        name: 'suite1',
        testCases: const [
          TestCase(
            name: 'test1',
            className: 'TestClass',
            status: TestStatus.skipped,
            time: Duration(milliseconds: 0),
          ),
          TestCase(
            name: 'test2',
            className: 'TestClass',
            status: TestStatus.passed,
            time: Duration(milliseconds: 200),
          ),
        ],
        time: const Duration(milliseconds: 200),
      );

      expect(testSuite.totalSkipped, equals(1));
    });
  });
}
