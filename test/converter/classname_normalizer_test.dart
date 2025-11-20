import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('ClassNameNormalizer', () {
    const generator = DefaultJUnitXmlGenerator();

    // Use reflection or test through public API
    // Since _normalizeClassName is private, we test it through the XML output
    String extractClassnameFromXml(String xmlString) {
      final classnameMatch = RegExp(r'classname="([^"]+)"').firstMatch(xmlString);
      return classnameMatch?.group(1) ?? '';
    }

    test('normalizes basic path with extension', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test.dart',
            testCases: const [
              TestCase(
                name: 'test',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('test.example_test'));
    });

    test('normalizes path with multiple directories and extension', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'lib/src/converter/junit_xml_generator.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'lib/src/converter/junit_xml_generator.dart',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('lib.src.converter.junit_xml_generator'));
    });

    test('normalizes path without extension', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example_test',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'test/example_test',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('test.example_test'));
    });

    test('normalizes path without slashes but with extension', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'example_test.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'example_test.dart',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('example_test'));
    });

    test('handles path without slashes and without extension', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'example_test',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'example_test',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('example_test'));
    });

    test('handles empty string', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: '',
            testCases: const [
              TestCase(
                name: 'test',
                className: '',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals(''));
    });

    test('handles only slashes', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: '///',
            testCases: const [
              TestCase(
                name: 'test',
                className: '///',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals(''));
    });

    test('handles only dots', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: '...',
            testCases: const [
              TestCase(
                name: 'test',
                className: '...',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals(''));
    });

    test('handles leading slash', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: '/test/example.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: '/test/example.dart',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('.test.example'));
    });

    test('handles trailing slash', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example/',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'test/example/',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('test.example.'));
    });

    test('handles consecutive slashes', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test//example.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'test//example.dart',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('test..example'));
    });

    test('handles multiple dots', () {
      final testResult = DartTestResult(
        suites: [
          TestSuite(
            name: 'test/example.test.dart',
            testCases: const [
              TestCase(
                name: 'test',
                className: 'test/example.test.dart',
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
      final classname = extractClassnameFromXml(xmlString);

      expect(classname, equals('test.example.test'));
    });
  });
}

