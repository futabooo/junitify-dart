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

    test('systemErr field is optional and can be null', () {
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

      expect(testSuite.systemErr, isNull);
    });

    test('systemErr field can contain error output', () {
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
        systemErr: 'Error line 1\nError line 2',
      );

      expect(testSuite.systemErr, equals('Error line 1\nError line 2'));
    });

    test('systemErr field can be empty string', () {
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
        systemErr: '',
      );

      expect(testSuite.systemErr, equals(''));
    });

    test('equals method includes systemErr field', () {
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
        systemErr: 'error',
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
        systemErr: 'error',
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
        systemErr: 'different',
      );

      expect(suite1, equals(suite2));
      expect(suite1, isNot(equals(suite3)));
    });

    test('hashCode includes systemErr field', () {
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
        systemErr: 'error',
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
        systemErr: 'error',
      );

      expect(suite1.hashCode, equals(suite2.hashCode));
    });

    test('systemOut and systemErr can be set simultaneously', () {
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
        systemOut: 'Output line',
        systemErr: 'Error line',
      );

      expect(testSuite.systemOut, equals('Output line'));
      expect(testSuite.systemErr, equals('Error line'));
    });

    test('platform field is optional and can be null', () {
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

      expect(testSuite.platform, isNull);
    });

    test('platform field can contain platform information', () {
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
        platform: 'linux',
      );

      expect(testSuite.platform, equals('linux'));
    });

    test('platform field can be empty string', () {
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
        platform: '',
      );

      expect(testSuite.platform, equals(''));
    });

    test('equals method includes platform field', () {
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
        platform: 'linux',
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
        platform: 'linux',
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
        platform: 'macos',
      );

      expect(suite1, equals(suite2));
      expect(suite1, isNot(equals(suite3)));
    });

    test('hashCode includes platform field', () {
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
        platform: 'linux',
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
        platform: 'linux',
      );

      expect(suite1.hashCode, equals(suite2.hashCode));
    });

    test('timestamp field is optional and can be null', () {
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

      expect(testSuite.timestamp, isNull);
    });

    test('timestamp field can contain DateTime value', () {
      final timestamp = DateTime(2025, 12, 2, 14, 25, 31);
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
        timestamp: timestamp,
      );

      expect(testSuite.timestamp, equals(timestamp));
    });

    test('equals method includes timestamp field', () {
      final timestamp1 = DateTime(2025, 12, 2, 14, 25, 31);
      final timestamp2 = DateTime(2025, 12, 2, 14, 25, 31);
      final timestamp3 = DateTime(2025, 12, 2, 14, 25, 32);

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
        timestamp: timestamp1,
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
        timestamp: timestamp2,
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
        timestamp: timestamp3,
      );

      expect(suite1, equals(suite2));
      expect(suite1, isNot(equals(suite3)));
    });

    test('equals method handles null timestamp correctly', () {
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
      );

      expect(suite1, equals(suite2));
    });

    test('hashCode includes timestamp field', () {
      final timestamp = DateTime(2025, 12, 2, 14, 25, 31);
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
        timestamp: timestamp,
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
        timestamp: timestamp,
      );

      expect(suite1.hashCode, equals(suite2.hashCode));
    });

    test('hashCode handles null timestamp correctly', () {
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
      );

      expect(suite1.hashCode, equals(suite2.hashCode));
    });
  });
}
