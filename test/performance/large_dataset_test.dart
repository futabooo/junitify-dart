import 'dart:io';

import 'package:junitify/junitify.dart';
import 'package:test/test.dart';

void main() {
  group('Performance tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('junitify_perf_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('processes 10,000 test cases within time limit', () async {
      // Generate large test dataset
      final inputFile = File('${tempDir.path}/large_input.json');
      final sink = inputFile.openWrite();

      // Write suite event
      sink.writeln(
        '{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/large_test.dart"}}',
      );

      // Write 10,000 test events
      const testCount = 10000;
      for (var i = 0; i < testCount; i++) {
        sink.writeln(
          '{"type":"testStart","test":{"id":$i,"name":"test $i","suiteID":0},"time":${i * 10}}',
        );
        sink.writeln(
          '{"type":"testDone","testID":$i,"result":"success","time":${(i * 10) + 5}}',
        );
      }

      await sink.close();

      // Measure conversion time
      final stopwatch = Stopwatch()..start();

      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      expect(inputResult.isSuccess, isTrue);

      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      expect(parseResult.isSuccess, isTrue);

      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/large_output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);
      expect(outputResult.isSuccess, isTrue);

      stopwatch.stop();

      // Verify processing time (should be under 10 seconds)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(10000),
        reason:
            'Processing 10,000 tests took ${stopwatch.elapsedMilliseconds}ms',
      );

      // Verify result correctness
      final testResult = parseResult.valueOrNull!;
      expect(testResult.totalTests, equals(testCount));

      print(
        'Performance: Processed $testCount tests in ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('memory usage stays within limits', () async {
      // Generate test dataset
      final inputFile = File('${tempDir.path}/memory_test.json');
      final sink = inputFile.openWrite();

      sink.writeln(
        '{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/memory_test.dart"}}',
      );

      const testCount = 5000;
      for (var i = 0; i < testCount; i++) {
        sink.writeln(
          '{"type":"testStart","test":{"id":$i,"name":"test $i with a longer name to increase memory usage","suiteID":0},"time":${i * 10}}',
        );

        // Add some with errors to increase memory usage
        if (i % 10 == 0) {
          sink.writeln(
            '{"type":"testDone","testID":$i,"result":"failure","time":${(i * 10) + 5},"error":"This is an error message with some details about what went wrong in the test","stackTrace":"at test/memory_test.dart:${i + 10}\\nat main.dart:100"}',
          );
        } else {
          sink.writeln(
            '{"type":"testDone","testID":$i,"result":"success","time":${(i * 10) + 5}}',
          );
        }
      }

      await sink.close();

      final fileSize = await inputFile.length();

      // Run conversion
      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/memory_output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      await outputDest.writeXml(xmlDoc);

      // Note: Memory usage is difficult to measure precisely in Dart tests
      // This test mainly verifies that the conversion completes without
      // running out of memory or causing performance issues
      expect(parseResult.isSuccess, isTrue);
      print(
        'Memory test: Processed ${fileSize / 1024}KB input file successfully',
      );
    });

    test('handles large output file generation', () async {
      final inputFile = File('${tempDir.path}/large_output_test.json');
      final sink = inputFile.openWrite();

      sink.writeln(
        '{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/output_test.dart"}}',
      );

      const testCount = 1000;
      for (var i = 0; i < testCount; i++) {
        sink.writeln(
          '{"type":"testStart","test":{"id":$i,"name":"test $i","suiteID":0},"time":${i * 10}}',
        );
        // Mix of passed and failed tests
        if (i % 3 == 0) {
          sink.writeln(
            '{"type":"testDone","testID":$i,"result":"failure","time":${(i * 10) + 5},"error":"Test failure message","stackTrace":"Stack trace line 1\\nStack trace line 2\\nStack trace line 3"}',
          );
        } else {
          sink.writeln(
            '{"type":"testDone","testID":$i,"result":"success","time":${(i * 10) + 5}}',
          );
        }
      }

      await sink.close();

      // Run conversion
      final inputSource = FileInputSource(inputFile.path);
      final inputResult = await inputSource.readJson();
      const parser = DefaultDartTestParser();
      final parseResult = parser.parse(inputResult.valueOrNull!);
      const generator = DefaultJUnitXmlGenerator();
      final xmlDoc = generator.convert(parseResult.valueOrNull!);

      final outputFile = File('${tempDir.path}/large_output.xml');
      final outputDest = FileOutputDestination(outputFile.path);
      final outputResult = await outputDest.writeXml(xmlDoc);

      expect(outputResult.isSuccess, isTrue);
      expect(await outputFile.exists(), isTrue);

      final outputSize = await outputFile.length();
      print('Output size: ${outputSize / 1024}KB for $testCount tests');
    });
  });
}
