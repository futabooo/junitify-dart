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

    test('systemOut field is optional and can be null', () {
      final testSuite = TestSuite(
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
      );

      expect(testSuite.systemOut, isNull);
    });

    test('systemOut field can contain standard output', () {
      final testSuite = TestSuite(
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
        systemOut: 'Output line 1\nOutput line 2',
      );

      expect(testSuite.systemOut, equals('Output line 1\nOutput line 2'));
    });

    test('systemOut field can be empty string', () {
      final testSuite = TestSuite(
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
        systemOut: '',
      );

      expect(testSuite.systemOut, equals(''));
    });

    test('equals method includes systemOut field', () {
      final suite1 = TestSuite(
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
        systemOut: 'output',
      );

      final suite2 = TestSuite(
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
        systemOut: 'output',
      );

      final suite3 = TestSuite(
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
        systemOut: 'different',
      );

      expect(suite1, equals(suite2));
      expect(suite1, isNot(equals(suite3)));
    });

    test('hashCode includes systemOut field', () {
      final suite1 = TestSuite(
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
        systemOut: 'output',
      );

      final suite2 = TestSuite(
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
        systemOut: 'output',
      );

      expect(suite1.hashCode, equals(suite2.hashCode));
    });
  });
}
