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
        // Attributes
        builder.attribute('name', suite.name);
        builder.attribute('tests', suite.totalTests.toString());
        builder.attribute('failures', suite.totalFailures.toString());
        builder.attribute('errors', suite.totalErrors.toString());
        builder.attribute('skipped', suite.totalSkipped.toString());
        builder.attribute('time', _formatDuration(suite.time));

        // System-out element (before testcase elements, per JUnit XML schema)
        if (suite.systemOut != null && suite.systemOut!.isNotEmpty) {
          builder.element('system-out', nest: () {
            builder.text(suite.systemOut!);
          });
        }

        // System-err element (after system-out, before testcase elements, per JUnit XML schema)
        if (suite.systemErr != null && suite.systemErr!.isNotEmpty) {
          builder.element('system-err', nest: () {
            builder.text(suite.systemErr!);
          });
        }

        // Test cases
        for (final testCase in suite.testCases) {
          _buildTestCase(builder, testCase);
        }
      },
    );
  }

  void _buildTestCase(XmlBuilder builder, TestCase testCase) {
    builder.element(
      'testcase',
      nest: () {
        // Attributes
        builder.attribute('name', testCase.name);
        builder.attribute('classname', testCase.className);
        builder.attribute('time', _formatDuration(testCase.time));

        // Status-specific elements
        switch (testCase.status) {
          case TestStatus.failed:
            _buildFailureElement(builder, testCase);
            break;
          case TestStatus.error:
            _buildErrorElement(builder, testCase);
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

  void _buildFailureElement(XmlBuilder builder, TestCase testCase) {
    builder.element(
      'failure',
      nest: () {
        if (testCase.errorMessage != null) {
          builder.attribute('message', testCase.errorMessage!);
        }
        builder.attribute('type', 'TestFailure');

        // Stack trace as text content
        if (testCase.stackTrace != null) {
          builder.text(testCase.stackTrace!);
        }
      },
    );
  }

  void _buildErrorElement(XmlBuilder builder, TestCase testCase) {
    builder.element(
      'error',
      nest: () {
        if (testCase.errorMessage != null) {
          builder.attribute('message', testCase.errorMessage!);
        }
        builder.attribute('type', 'TestError');

        // Stack trace as text content
        if (testCase.stackTrace != null) {
          builder.text(testCase.stackTrace!);
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
}
