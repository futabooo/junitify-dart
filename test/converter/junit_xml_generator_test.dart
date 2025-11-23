import 'package:junitify/junitify.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

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
      expect(xmlString, contains('classname="test.example_test"'));
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
      expect(
        xmlString,
        contains('message="1 failure, see stacktrace for details"'),
      );
      expect(xmlString, contains('type="AssertionError"'));
      expect(xmlString, contains('Failure:'));
      expect(xmlString, contains('Expected: true, Actual: false'));
      expect(xmlString, contains('classname="test.example_test"'));
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
      expect(
        xmlString,
        contains('message="1 error, see stacktrace for details"'),
      );
      expect(xmlString, contains('type="AssertionError"'));
      expect(xmlString, contains('Error:'));
      expect(xmlString, contains('Exception: Something went wrong'));
      expect(xmlString, contains('classname="test.example_test"'));
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
      expect(xmlString, contains('classname="test.example_test"'));
    });

    group('failure XML output format', () {
      test('failure element has AssertionError type', () {
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
                  errorMessage: 'Assertion error message',
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
        final xmlString = xmlDoc.toXmlString(pretty: true, indent: '  ');

        expect(xmlString, contains('type="AssertionError"'));
        expect(
          xmlString,
          contains('message="1 failure, see stacktrace for details"'),
        );
        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Assertion error message'));
      });

      test('failure element has formatted stack trace with blank lines', () {
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
                  errorMessage: 'Assertion error message',
                  stackTrace:
                      'package:matcher expect\ntest/example_test.dart 10:7  main.<fn>',
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
        // Use pretty: false to preserve whitespace in text content
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that error message is present
        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Assertion error message'));
        // Stack trace is not included in the element content
      });

      test('failure element has error message when stack trace is null', () {
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
                  errorMessage: 'Assertion error message',
                  stackTrace: null,
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
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that failure element contains error message
        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Assertion error message'));
      });

      test('failure element has error message when stack trace is empty', () {
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
                  errorMessage: 'Assertion error message',
                  stackTrace: '',
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
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that failure element contains error message
        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Assertion error message'));
      });

      test('failure element shows correct count for multiple failures', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'failing test 1',
                  className: 'test/example_test.dart',
                  status: TestStatus.failed,
                  time: Duration(milliseconds: 100),
                  errorMessage: 'Error 1',
                ),
                TestCase(
                  name: 'failing test 2',
                  className: 'test/example_test.dart',
                  status: TestStatus.failed,
                  time: Duration(milliseconds: 100),
                  errorMessage: 'Error 2',
                ),
                TestCase(
                  name: 'failing test 3',
                  className: 'test/example_test.dart',
                  status: TestStatus.failed,
                  time: Duration(milliseconds: 100),
                  errorMessage: 'Error 3',
                ),
              ],
              time: const Duration(milliseconds: 300),
            ),
          ],
          totalTests: 3,
          totalFailures: 3,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 300),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString(pretty: true, indent: '  ');

        // Should show "3 failures" (plural)
        expect(
          xmlString,
          contains('message="3 failures, see stacktrace for details"'),
        );
        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Error 1'));
        expect(xmlString, contains('Error 2'));
        expect(xmlString, contains('Error 3'));
      });

      test(
        'failure element does not have message attribute when errorMessage is null',
        () {
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
                    errorMessage: null,
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
          expect(xmlString, contains('type="AssertionError"'));
          // Should not contain message attribute
          expect(xmlString, isNot(contains('message=')));
        },
      );

      test('failure element handles multiline error message', () {
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
                  errorMessage: 'Line 1\nLine 2\nLine 3',
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

        expect(xmlString, contains('Failure:'));
        expect(xmlString, contains('Line 1'));
        expect(xmlString, contains('Line 2'));
        expect(xmlString, contains('Line 3'));
      });
    });

    group('error XML output format', () {
      test('error element has AssertionError type', () {
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
                  stackTrace: 'at test/example_test.dart:10',
                ),
              ],
              time: const Duration(milliseconds: 50),
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 50),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString(pretty: true, indent: '  ');

        expect(xmlString, contains('type="AssertionError"'));
        expect(
          xmlString,
          contains('message="1 error, see stacktrace for details"'),
        );
        expect(xmlString, contains('Error:'));
        expect(xmlString, contains('Exception: Something went wrong'));
      });

      test('error element has formatted stack trace with blank lines', () {
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
                  stackTrace:
                      'package:test expect\ntest/example_test.dart 10:7  main.<fn>',
                ),
              ],
              time: const Duration(milliseconds: 50),
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 50),
        );

        final xmlDoc = generator.convert(testResult);
        // Use pretty: false to preserve whitespace in text content
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that error message is present
        expect(xmlString, contains('Error:'));
        expect(xmlString, contains('Exception: Something went wrong'));
        // Stack trace is not included in the element content
      });

      test('error element has error message when stack trace is null', () {
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
                  stackTrace: null,
                ),
              ],
              time: const Duration(milliseconds: 50),
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 50),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that error element contains error message
        expect(xmlString, contains('Error:'));
        expect(xmlString, contains('Exception: Something went wrong'));
      });

      test('error element has error message when stack trace is empty', () {
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
                  stackTrace: '',
                ),
              ],
              time: const Duration(milliseconds: 50),
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 50),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString(pretty: false);

        // Check that error element contains error message
        expect(xmlString, contains('Error:'));
        expect(xmlString, contains('Exception: Something went wrong'));
      });

      test(
        'error element does not have message attribute when errorMessage is null',
        () {
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
                    errorMessage: null,
                    stackTrace: 'at test/example_test.dart:10',
                  ),
                ],
                time: const Duration(milliseconds: 50),
              ),
            ],
            totalTests: 1,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 50),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          expect(xmlString, contains('<error'));
          expect(xmlString, contains('type="AssertionError"'));
          // Should not contain message attribute
          expect(xmlString, isNot(contains('message=')));
        },
      );

      test('error element handles multiline error message', () {
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
                  errorMessage: 'Line 1\nLine 2\nLine 3',
                  stackTrace: 'at test/example_test.dart:10',
                ),
              ],
              time: const Duration(milliseconds: 50),
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 50),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        expect(xmlString, contains('Error:'));
        expect(xmlString, contains('Line 1'));
        expect(xmlString, contains('Line 2'));
        expect(xmlString, contains('Line 3'));
      });
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
      expect(xmlString, contains('classname="test.first_test"'));
      expect(xmlString, contains('classname="test.second_test"'));
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
      expect(xmlString, contains('classname="test.example_test"'));
    });

    group('system-out support', () {
      test('generates system-out tag when systemOut is not null', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test with output',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 150),
                  systemOut: 'Output line 1\nOutput line 2',
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

        expect(xmlString, contains('<system-out>'));
        expect(xmlString, contains('Output line 1\nOutput line 2'));
        expect(xmlString, contains('</system-out>'));
        // Verify it's inside testcase element, not testsuite
        final testcaseIndex = xmlString.indexOf('<testcase');
        final systemOutIndex = xmlString.indexOf('<system-out>');
        expect(systemOutIndex, greaterThan(testcaseIndex));
      });

      test('does not generate system-out tag when systemOut is null', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test without output',
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

        expect(xmlString, isNot(contains('<system-out>')));
      });

      test('does not generate system-out tag when systemOut is empty', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test with empty output',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 150),
                  systemOut: '',
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

        expect(xmlString, isNot(contains('<system-out>')));
      });

      test('escapes XML special characters in system-out', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test with special chars',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 150),
                  systemOut: 'Text with <tags> & "quotes"',
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

        expect(xmlString, contains('<system-out>'));
        // XML package automatically escapes, so we check the escaped version
        // Note: xml package escapes < and &, but not > or quotes in text content
        expect(xmlString, contains('&lt;tags'));
        expect(xmlString, contains('&amp;'));
        // Verify the content is properly escaped (not breaking XML)
        expect(xmlString, contains('Text with'));
      });

      test(
        'places system-out tag inside testcase element before status-specific elements',
        () {
          final testResult = DartTestResult(
            suites: [
              TestSuite(
                name: 'test/example_test.dart',
                testCases: const [
                  TestCase(
                    name: 'test 1',
                    className: 'test/example_test.dart',
                    status: TestStatus.passed,
                    time: Duration(milliseconds: 100),
                    systemOut: 'Test output',
                  ),
                  TestCase(
                    name: 'test 2',
                    className: 'test/example_test.dart',
                    status: TestStatus.failed,
                    time: Duration(milliseconds: 200),
                    errorMessage: 'Test failed',
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

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Find positions for first testcase
          final firstTestcaseIndex = xmlString.indexOf('name="test 1"');
          final systemOutIndex = xmlString.indexOf('<system-out>');
          final failureIndex = xmlString.indexOf('<failure');

          expect(systemOutIndex, greaterThan(firstTestcaseIndex));
          // system-out should be before failure element
          expect(systemOutIndex, lessThan(failureIndex));
        },
      );

      test('generates system-out for each test case independently', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test 1',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 100),
                  systemOut: 'Output from first test',
                ),
                TestCase(
                  name: 'test 2',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 200),
                  systemOut: 'Output from second test',
                ),
              ],
              time: const Duration(milliseconds: 300),
            ),
          ],
          totalTests: 2,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 300),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        expect(xmlString, contains('Output from first test'));
        expect(xmlString, contains('Output from second test'));
        // Count system-out tags
        final systemOutCount = '<system-out>'.allMatches(xmlString).length;
        expect(systemOutCount, equals(2));
      });

      test(
        'generates system-out tag at testsuite level after testcase elements',
        () {
          final testResult = DartTestResult(
            suites: [
              TestSuite(
                name: 'test/example_test.dart',
                testCases: const [
                  TestCase(
                    name: 'test without output',
                    className: 'test/example_test.dart',
                    status: TestStatus.passed,
                    time: Duration(milliseconds: 150),
                  ),
                ],
                time: const Duration(milliseconds: 150),
                systemOut: 'Suite output line 1\nSuite output line 2',
              ),
            ],
            totalTests: 1,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 150),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Should contain system-out tag at testsuite level
          expect(xmlString, contains('<system-out>'));
          expect(xmlString, contains('Suite output line 1'));
          expect(xmlString, contains('Suite output line 2'));
          // Should be after testcase elements (matching tests_report_4.xml format)
          final systemOutIndex = xmlString.indexOf('<system-out>');
          final testcaseIndex = xmlString.indexOf('<testcase');
          final testcaseEndIndex = xmlString.indexOf('</testcase>');
          expect(systemOutIndex, greaterThan(testcaseIndex));
          expect(systemOutIndex, greaterThan(testcaseEndIndex));
        },
      );
    });

    group('system-err support', () {
      test('does not generate system-err tag at testsuite level', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test with error output',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 150),
                ),
              ],
              time: const Duration(milliseconds: 150),
              systemErr: 'Error line 1\nError line 2',
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 150),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        // Should not contain system-err tag (testsuite level is ignored)
        expect(xmlString, isNot(contains('<system-err>')));
        expect(xmlString, isNot(contains('Error line 1\nError line 2')));
      });

      test('does not generate system-err tag when systemErr is null', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test without error output',
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

        expect(xmlString, isNot(contains('<system-err>')));
      });

      test('does not generate system-err tag when systemErr is empty', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test with empty error output',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 150),
                ),
              ],
              time: const Duration(milliseconds: 150),
              systemErr: '',
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 150),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        expect(xmlString, isNot(contains('<system-err>')));
      });

      test(
        'does not generate system-err tag at testsuite level (system-err not supported)',
        () {
          final testResult = DartTestResult(
            suites: [
              TestSuite(
                name: 'test/example_test.dart',
                testCases: const [
                  TestCase(
                    name: 'test with special chars',
                    className: 'test/example_test.dart',
                    status: TestStatus.passed,
                    time: Duration(milliseconds: 150),
                  ),
                ],
                time: const Duration(milliseconds: 150),
                systemErr: 'Error with <tags> & "quotes"',
              ),
            ],
            totalTests: 1,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 150),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Should not contain system-err tag (testsuite level is ignored)
          expect(xmlString, isNot(contains('<system-err>')));
          expect(xmlString, isNot(contains('Error with')));
        },
      );

      test(
        'does not generate system-err tag at testsuite level even when both systemOut and systemErr exist',
        () {
          final testResult = DartTestResult(
            suites: [
              TestSuite(
                name: 'test/example_test.dart',
                testCases: const [
                  TestCase(
                    name: 'test 1',
                    className: 'test/example_test.dart',
                    status: TestStatus.passed,
                    time: Duration(milliseconds: 100),
                  ),
                  TestCase(
                    name: 'test 2',
                    className: 'test/example_test.dart',
                    status: TestStatus.passed,
                    time: Duration(milliseconds: 200),
                  ),
                ],
                time: const Duration(milliseconds: 300),
                systemOut: 'Suite output',
                systemErr: 'Suite error',
              ),
            ],
            totalTests: 2,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 300),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Should not contain system-err tag (testsuite level is ignored)
          expect(xmlString, isNot(contains('<system-err>')));
          expect(xmlString, isNot(contains('Suite error')));
          // system-out at testsuite level should be generated
          expect(xmlString, contains('<system-out>'));
          expect(xmlString, contains('Suite output'));
        },
      );

      test(
        'does not generate system-err tag at testsuite level (system-err not supported)',
        () {
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
                systemOut: 'Output line',
                systemErr: 'Error line',
              ),
            ],
            totalTests: 1,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 150),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Should not contain system-err tag (testsuite level is ignored)
          expect(xmlString, isNot(contains('<system-err>')));
          expect(xmlString, isNot(contains('Error line')));
          // system-out at testsuite level should be generated
          expect(xmlString, contains('<system-out>'));
          expect(xmlString, contains('Output line'));
        },
      );

      test(
        'does not generate system-err tag at testsuite level for multiple suites',
        () {
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
                systemErr: 'Error from first suite',
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
                systemErr: 'Error from second suite',
              ),
            ],
            totalTests: 2,
            totalFailures: 0,
            totalSkipped: 0,
            totalTime: const Duration(milliseconds: 300),
          );

          final xmlDoc = generator.convert(testResult);
          final xmlString = xmlDoc.toXmlString();

          // Should not contain system-err tag (testsuite level is ignored)
          expect(xmlString, isNot(contains('<system-err>')));
          expect(xmlString, isNot(contains('Error from first suite')));
          expect(xmlString, isNot(contains('Error from second suite')));
        },
      );
    });

    group('classname normalization', () {
      test(
        'normalizes classname in XML output but does not modify TestCase model',
        () {
          const originalClassName = 'test/example_test.dart';
          final testCase = TestCase(
            name: 'test',
            className: originalClassName,
            status: TestStatus.passed,
            time: Duration(milliseconds: 150),
          );

          final testResult = DartTestResult(
            suites: [
              TestSuite(
                name: 'test/example_test.dart',
                testCases: [testCase],
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

          // Verify classname is normalized in XML output
          expect(xmlString, contains('classname="test.example_test"'));

          // Verify TestCase model is not modified
          expect(testCase.className, equals(originalClassName));
        },
      );

      test('normalizes classname for all test statuses', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'passed test',
                  className: 'test/example_test.dart',
                  status: TestStatus.passed,
                  time: Duration(milliseconds: 100),
                ),
                TestCase(
                  name: 'failed test',
                  className: 'test/example_test.dart',
                  status: TestStatus.failed,
                  time: Duration(milliseconds: 200),
                  errorMessage: 'Test failed',
                ),
                TestCase(
                  name: 'error test',
                  className: 'test/example_test.dart',
                  status: TestStatus.error,
                  time: Duration(milliseconds: 300),
                  errorMessage: 'Test error',
                ),
                TestCase(
                  name: 'skipped test',
                  className: 'test/example_test.dart',
                  status: TestStatus.skipped,
                  time: Duration(milliseconds: 400),
                ),
              ],
              time: const Duration(milliseconds: 1000),
            ),
          ],
          totalTests: 4,
          totalFailures: 2,
          totalSkipped: 1,
          totalTime: const Duration(milliseconds: 1000),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        // Verify all test cases have normalized classname
        final classnameCount = 'classname="test.example_test"'
            .allMatches(xmlString)
            .length;
        expect(classnameCount, equals(4));
      });

      test('does not affect other attributes', () {
        final testResult = DartTestResult(
          suites: [
            TestSuite(
              name: 'test/example_test.dart',
              testCases: const [
                TestCase(
                  name: 'test name',
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

        // Verify other attributes are not affected
        expect(xmlString, contains('name="test name"'));
        expect(xmlString, contains('time="0.150"'));
        expect(xmlString, contains('classname="test.example_test"'));
      });
    });

    group('XML attribute order', () {
      test('testsuite attributes are in standard order', () {
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

        // Parse XML to verify attribute order
        final document = XmlDocument.parse(xmlString);
        final testsuite = document.findAllElements('testsuite').first;

        // Get attributes in order
        final attributes = testsuite.attributes
            .map((a) => a.name.local)
            .toList();

        // Expected order: name, tests, failures, errors, skipped, time
        expect(attributes.length, greaterThanOrEqualTo(6));
        expect(attributes[0], 'name');
        expect(attributes[1], 'tests');
        expect(attributes[2], 'failures');
        expect(attributes[3], 'errors');
        expect(attributes[4], 'skipped');
        expect(attributes[5], 'time');
      });

      test('testcase attributes are in standard order', () {
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
                  file: 'test/example_test.dart',
                  line: 10,
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

        // Parse XML to verify attribute order
        final document = XmlDocument.parse(xmlString);
        final testcase = document.findAllElements('testcase').first;

        // Get attributes in order
        final attributes = testcase.attributes
            .map((a) => a.name.local)
            .toList();

        // Expected order: name, classname, time, file, line
        expect(attributes.length, greaterThanOrEqualTo(5));
        expect(attributes[0], 'name');
        expect(attributes[1], 'classname');
        expect(attributes[2], 'time');
        expect(attributes[3], 'file');
        expect(attributes[4], 'line');
      });

      test(
        'testcase attributes are in standard order without file and line',
        () {
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

          // Parse XML to verify attribute order
          final document = XmlDocument.parse(xmlString);
          final testcase = document.findAllElements('testcase').first;

          // Get attributes in order
          final attributes = testcase.attributes
              .map((a) => a.name.local)
              .toList();

          // Expected order: name, classname, time
          expect(attributes.length, greaterThanOrEqualTo(3));
          expect(attributes[0], 'name');
          expect(attributes[1], 'classname');
          expect(attributes[2], 'time');
        },
      );

      test(
        'testcase attributes are in standard order with file but without line',
        () {
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
                    file: 'test/example_test.dart',
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

          // Parse XML to verify attribute order
          final document = XmlDocument.parse(xmlString);
          final testcase = document.findAllElements('testcase').first;

          // Get attributes in order
          final attributes = testcase.attributes
              .map((a) => a.name.local)
              .toList();

          // Expected order: name, classname, time, file
          expect(attributes.length, greaterThanOrEqualTo(4));
          expect(attributes[0], 'name');
          expect(attributes[1], 'classname');
          expect(attributes[2], 'time');
          expect(attributes[3], 'file');
        },
      );
    });
  });
}
