import 'package:xml/xml.dart';

import '../models/dart_test_result.dart';
import '../models/test_case.dart';
import '../models/test_status.dart';
import '../models/test_suite.dart';

/// Interface for generating JUnit XML from Dart test results.
abstract class JUnitXmlGenerator {
  /// Converts a DartTestResult to a JUnit XML document.
  XmlDocument convert(DartTestResult testResult);
}

/// Default implementation of JUnitXmlGenerator.
class DefaultJUnitXmlGenerator implements JUnitXmlGenerator {
  const DefaultJUnitXmlGenerator();

  @override
  XmlDocument convert(DartTestResult testResult) {
    final builder = XmlBuilder();

    // XML declaration is automatically added by XmlDocument
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    // Root element: testsuites
    builder.element(
      'testsuites',
      nest: () {
        for (final suite in testResult.suites) {
          _buildTestSuite(builder, suite);
        }
      },
    );

    return builder.buildDocument();
  }

  void _buildTestSuite(XmlBuilder builder, TestSuite suite) {
    builder.element(
      'testsuite',
      nest: () {
        // Attributes in standard JUnit XML order:
        // name, tests, failures, errors, skipped, time, timestamp (optional)
        // Reference: https://github.com/testmoapp/junitxml
        builder.attribute('name', suite.name);
        builder.attribute('tests', suite.totalTests.toString());
        builder.attribute('failures', suite.totalFailures.toString());
        builder.attribute('errors', suite.totalErrors.toString());
        builder.attribute('skipped', suite.totalSkipped.toString());
        builder.attribute('time', _formatDuration(suite.time));

        // Test cases
        for (final testCase in suite.testCases) {
          _buildTestCase(builder, testCase, suite);
        }

        // System-out element (after testcase elements, matching tests_report_4.xml format)
        if (suite.systemOut != null && suite.systemOut!.isNotEmpty) {
          builder.element(
            'system-out',
            nest: () {
              builder.text(suite.systemOut!);
            },
          );
        }
      },
    );
  }

  void _buildTestCase(XmlBuilder builder, TestCase testCase, TestSuite suite) {
    builder.element(
      'testcase',
      nest: () {
        // Attributes in standard JUnit XML order:
        // name, classname, time, file (optional), line (optional)
        // Reference: https://github.com/testmoapp/junitxml
        builder.attribute('name', testCase.name);
        builder.attribute('classname', _normalizeClassName(testCase.className));
        builder.attribute('time', _formatDuration(testCase.time));

        // File and line attributes
        if (testCase.file != null) {
          builder.attribute('file', testCase.file!);
        }
        if (testCase.line != null) {
          builder.attribute('line', testCase.line!.toString());
        }

        // System-out element (before status-specific elements, per JUnit XML schema)
        if (testCase.systemOut != null && testCase.systemOut!.isNotEmpty) {
          builder.element(
            'system-out',
            nest: () {
              builder.text(testCase.systemOut!);
            },
          );
        }

        // Status-specific elements
        switch (testCase.status) {
          case TestStatus.failed:
            _buildFailureElement(builder, testCase, suite);
            break;
          case TestStatus.error:
            _buildErrorElement(builder, testCase, suite);
            break;
          case TestStatus.skipped:
            _buildSkippedElement(builder);
            break;
          case TestStatus.passed:
            // No additional elements for passed tests
            break;
        }
      },
    );
  }

  void _buildFailureElement(
    XmlBuilder builder,
    TestCase testCase,
    TestSuite suite,
  ) {
    builder.element(
      'failure',
      nest: () {
        // Set a short message in the message attribute with actual failure count
        if (testCase.errorMessage != null) {
          builder.attribute(
            'message',
            '${suite.totalFailures} failure${suite.totalFailures != 1 ? 's' : ''}, see stacktrace for details',
          );
        }
        builder.attribute('type', 'AssertionError');

        // Output error message as element content with "Failure:" prefix
        if (testCase.errorMessage != null) {
          builder.text('Failure:\n${testCase.errorMessage!}');
        }
      },
    );
  }

  void _buildErrorElement(
    XmlBuilder builder,
    TestCase testCase,
    TestSuite suite,
  ) {
    builder.element(
      'error',
      nest: () {
        // Set a short message in the message attribute with actual error count
        if (testCase.errorMessage != null) {
          builder.attribute(
            'message',
            '${suite.totalErrors} error${suite.totalErrors != 1 ? 's' : ''}, see stacktrace for details',
          );
        }
        builder.attribute('type', 'AssertionError');

        // Output error message as element content with "Error:" prefix
        if (testCase.errorMessage != null) {
          builder.text('Error:\n${testCase.errorMessage!}');
        }
      },
    );
  }

  void _buildSkippedElement(XmlBuilder builder) {
    builder.element('skipped');
  }

  String _formatDuration(Duration duration) {
    // Convert to seconds with millisecond precision
    return (duration.inMilliseconds / 1000.0).toStringAsFixed(3);
  }

  /// Normalizes a classname string by converting slashes to dots and removing the extension.
  ///
  /// Converts slashes (`/`) to dots (`.`) and removes the last extension part (e.g., `.dart`).
  ///
  /// Examples:
  ///   - `test/example_test.dart` → `test.example_test`
  ///   - `lib/src/converter/junit_xml_generator.dart` → `lib.src.converter.junit_xml_generator`
  ///   - `test/example_test` → `test.example_test`
  ///   - `example_test.dart` → `example_test`
  ///   - `example_test` → `example_test`
  ///   - `///` → `` (empty string)
  ///   - `/test/example.dart` → `.test.example`
  ///   - `test/example/` → `test.example.`
  ///   - `test//example.dart` → `test..example`
  ///
  /// Parameters:
  ///   [className] - The classname string to normalize
  ///
  /// Returns:
  ///   The normalized classname string
  String _normalizeClassName(String className) {
    // Handle empty string
    if (className.isEmpty) {
      return className;
    }

    // Replace all slashes with dots
    var normalized = className.replaceAll('/', '.');

    // Remove the extension (last dot and everything after it)
    // Only remove if there's at least one character after the last dot
    final lastDotIndex = normalized.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < normalized.length - 1) {
      // Check if the part after the last dot looks like an extension
      // (contains only alphanumeric characters, typical for file extensions)
      final afterLastDot = normalized.substring(lastDotIndex + 1);
      if (afterLastDot.isNotEmpty &&
          afterLastDot.codeUnits.every(
            (code) =>
                (code >= 48 && code <= 57) || // 0-9
                (code >= 65 && code <= 90) || // A-Z
                (code >= 97 && code <= 122),
          )) {
        // It's likely an extension, remove it
        normalized = normalized.substring(0, lastDotIndex);
      }
    }

    // Handle edge case: if result is only dots (e.g., `///` → `...` → ``)
    // or if result becomes empty after extension removal
    if (normalized.isEmpty ||
        normalized.codeUnits.every((code) => code == 46)) {
      return '';
    }

    return normalized;
  }
}
