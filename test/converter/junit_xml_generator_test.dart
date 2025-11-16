import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultJUnitXmlGenerator', () {
    const generator = DefaultJUnitXmlGenerator();

    test('generates valid JUnit XML for passed test', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'example test',
                className: 'test/example_test.dart',
                status: TestStatus.passed,
                time: Duration(milliseconds: 150),
              ),
            ],
            time: const Duration(milliseconds: 150),
          ),
        ],
        totalTests: 1,
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 150),
      );

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('<testsuites>'));
      expect(xmlString, contains('<testsuite'));
      expect(xmlString, contains('name="test/example_test.dart"'));
      expect(xmlString, contains('tests="1"'));
      expect(xmlString, contains('failures="0"'));
      expect(xmlString, contains('<testcase'));
      expect(xmlString, contains('name="example test"'));
      expect(xmlString, contains('time="0.150"'));
    });

    test('includes failure element for failed test', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'failing test',
                className: 'test/example_test.dart',
                status: TestStatus.failed,
                time: Duration(milliseconds: 100),
                errorMessage: 'Expected: true, Actual: false',
                stackTrace: 'at test/example_test.dart:10',
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

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('<failure'));
      expect(xmlString, contains('message="Expected: true, Actual: false"'));
      expect(xmlString, contains('type="TestFailure"'));
      expect(xmlString, contains('at test/example_test.dart:10'));
    });

    test('includes error element for error test', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'error test',
                className: 'test/example_test.dart',
                status: TestStatus.error,
                time: Duration(milliseconds: 50),
                errorMessage: 'Exception: Something went wrong',
              ),
            ],
            time: const Duration(milliseconds: 50),
          ),
        ],
        totalTests: 1,
        totalFailures: 1,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 50),
      );

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('<error'));
      expect(xmlString, contains('type="TestError"'));
    });

    test('includes skipped element for skipped test', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'skipped test',
                className: 'test/example_test.dart',
                status: TestStatus.skipped,
                time: Duration.zero,
              ),
            ],
            time: Duration.zero,
          ),
        ],
        totalTests: 1,
        totalFailures: 0,
        totalSkipped: 1,
        totalTime: Duration.zero,
      );

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('<skipped'));
      expect(xmlString, contains('skipped="1"'));
    });

    test('handles multiple test suites', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/first_test.dart',
            testCases: const [
              TestCase(
                name: 'test 1',
                className: 'test/first_test.dart',
                status: TestStatus.passed,
                time: Duration(milliseconds: 100),
              ),
            ],
            time: const Duration(milliseconds: 100),
          ),
          TestSuite(
            name: 'test/second_test.dart',
            testCases: const [
              TestCase(
                name: 'test 2',
                className: 'test/second_test.dart',
                status: TestStatus.passed,
                time: Duration(milliseconds: 200),
              ),
            ],
            time: const Duration(milliseconds: 200),
          ),
        ],
        totalTests: 2,
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 300),
      );

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('test/first_test.dart'));
      expect(xmlString, contains('test/second_test.dart'));
    });

    test('formats time correctly', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'test/example_test.dart',
                status: TestStatus.passed,
                time: Duration(milliseconds: 1234),
              ),
            ],
            time: const Duration(milliseconds: 1234),
          ),
        ],
        totalTests: 1,
        totalFailures: 0,
        totalSkipped: 0,
        totalTime: const Duration(milliseconds: 1234),
      );

      final xmlDoc = generator.convert(testResult);
      final xmlString = xmlDoc.toXmlString();

      expect(xmlString, contains('time="1.234"'));
    });
  });
}
