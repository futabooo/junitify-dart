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

      test('does not generate system-out tag at testsuite level', () {
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
              systemOut: 'Suite output that should be ignored',
            ),
          ],
          totalTests: 1,
          totalFailures: 0,
          totalSkipped: 0,
          totalTime: const Duration(milliseconds: 150),
        );

        final xmlDoc = generator.convert(testResult);
        final xmlString = xmlDoc.toXmlString();

        // Should not contain system-out tag (testsuite level is ignored)
        expect(xmlString, isNot(contains('<system-out>')));
        expect(
          xmlString,
          isNot(contains('Suite output that should be ignored')),
        );
      });
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
          // system-out at testsuite level should also be ignored
          expect(xmlString, isNot(contains('Suite output')));
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
          // system-out at testsuite level should also be ignored
          expect(xmlString, isNot(contains('Output line')));
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
  });
}
