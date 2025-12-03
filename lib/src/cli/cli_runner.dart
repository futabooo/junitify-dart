import 'package:args/args.dart';

import '../common/error.dart';
import '../converter/junit_xml_generator.dart';
import '../error/error_reporter.dart';
import '../input/input_source.dart';
import '../output/output_destination.dart';
import '../parser/dart_test_parser.dart';
import 'cli_config.dart';

/// Interface for running the CLI application.
abstract class CliRunner {
  /// Runs the CLI with the given arguments.
  ///
  /// Returns exit code: 0 for success, 1 for error.
  Future<int> run(List<String> arguments);
}

/// Default implementation of CliRunner.
class DefaultCliRunner implements CliRunner {
  DefaultCliRunner({required this.parser, required this.generator});

  final DartTestParser parser;
  final JUnitXmlGenerator generator;

  static const String version = '0.1.0';

  @override
  Future<int> run(List<String> arguments) async {
    // Parse arguments
    final argParser = _createArgParser();
    late ArgResults results;

    try {
      results = argParser.parse(arguments);
    } catch (e) {
      _printError('Invalid arguments: $e');
      _printUsage(argParser);
      return 1;
    }

    final config = _buildConfig(results);

    // Handle help
    if (config.showHelp) {
      _printUsage(argParser);
      return 0;
    }

    // Handle version
    if (config.showVersion) {
      print('junitify version $version');
      return 0;
    }

    // Create error reporter
    final errorReporter = ConsoleErrorReporter(debugMode: config.debugMode);

    // Run conversion
    return await _runConversion(config, errorReporter);
  }

  Future<int> _runConversion(
    CliConfig config,
    ErrorReporter errorReporter,
  ) async {
    try {
      // 1. Read input
      final inputSource = config.inputPath != null
          ? FileInputSource(config.inputPath!)
          : const StdinInputSource();

      errorReporter.debug('Reading input from ${config.inputPath ?? "stdin"}');
      final inputResult = await inputSource.readJson();

      if (inputResult.isFailure) {
        final error = InputPhaseError(inputResult.errorOrNull!);
        errorReporter.reportError(error);
        return 1;
      }

      final jsonString = inputResult.valueOrNull!;
      errorReporter.debug(
        'Input read successfully (${jsonString.length} bytes)',
      );

      // 2. Parse JSON
      errorReporter.debug('Parsing Dart test JSON');
      final parseResult = parser.parse(
        jsonString,
        errorReporter: errorReporter,
        fileRelativeTo: config.fileRelativeTo,
      );

      if (parseResult.isFailure) {
        final error = ParsingPhaseError(parseResult.errorOrNull!);
        errorReporter.reportError(error);
        return 1;
      }

      final testResult = parseResult.valueOrNull!;
      errorReporter.debug(
        'Parsed ${testResult.totalTests} tests from ${testResult.suites.length} suites',
      );

      // 3. Validate timestamp option if specified
      if (config.timestampOption != null) {
        final timestampOption = config.timestampOption!;
        if (timestampOption != 'now' &&
            timestampOption != 'none' &&
            !_isValidTimestampFormat(timestampOption)) {
          _printError(
            'Invalid timestamp option: "$timestampOption". '
            'Expected "now", "none", or "yyyy-MM-ddTHH:mm:ss" format.',
          );
          return 1;
        }
      }

      // 4. Convert to XML
      errorReporter.debug('Converting to JUnit XML');
      final xmlDocument = generator.convert(
        testResult,
        inputPath: config.inputPath,
        timestampOption: config.timestampOption,
      );
      errorReporter.debug('Conversion successful');

      // 5. Write output
      final outputDest = config.outputPath != null
          ? FileOutputDestination(config.outputPath!)
          : const StdoutOutputDestination();

      errorReporter.debug('Writing output to ${config.outputPath ?? "stdout"}');
      final outputResult = await outputDest.writeXml(xmlDocument);

      if (outputResult.isFailure) {
        final error = OutputPhaseError(outputResult.errorOrNull!);
        errorReporter.reportError(error);
        return 1;
      }

      errorReporter.debug('Output written successfully');
      return 0;
    } catch (e, stackTrace) {
      _printError('Unexpected error: $e');
      if (config.debugMode) {
        _printError('Stack trace:\n$stackTrace');
      }
      return 1;
    }
  }

  ArgParser _createArgParser() {
    return ArgParser()
      ..addOption(
        'input',
        abbr: 'i',
        help: 'Input JSON file path (default: stdin)',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output XML file path (default: stdout)',
      )
      ..addOption(
        'file-relative-to',
        abbr: 'r',
        help:
            "the relative path to calculate the path defined in the 'file' element in the test from",
        defaultsTo: '.',
      )
      ..addOption(
        'timestamp',
        abbr: 't',
        help:
            'Timestamp option: "now" (current time), "none" (no timestamp), or "yyyy-MM-ddTHH:mm:ss" format',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show this usage information',
      )
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Show version information',
      )
      ..addFlag(
        'debug',
        negatable: false,
        help: 'Enable debug mode with detailed output',
      );
  }

  CliConfig _buildConfig(ArgResults results) {
    return CliConfig(
      inputPath: results['input'] as String?,
      outputPath: results['output'] as String?,
      showHelp: results['help'] as bool,
      showVersion: results['version'] as bool,
      debugMode: results['debug'] as bool,
      fileRelativeTo: results['file-relative-to'] as String?,
      timestampOption: results['timestamp'] as String?,
    );
  }

  /// Validates if a string matches the yyyy-MM-ddTHH:mm:ss format.
  bool _isValidTimestampFormat(String value) {
    // Basic format validation: yyyy-MM-ddTHH:mm:ss
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$');
    if (!pattern.hasMatch(value)) {
      return false;
    }

    // Try to parse to ensure it's a valid date/time
    try {
      DateTime.parse(value);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _printUsage(ArgParser parser) {
    print('Usage: junitify [options]');
    print('');
    print('Convert Dart test JSON output to JUnit XML format.');
    print('');
    print('Options:');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  # Convert from file to file');
    print('  junitify -i test_output.json -o junit_output.xml');
    print('');
    print('  # Convert from stdin to stdout');
    print('  dart test --reporter=json | junitify');
    print('');
    print('  # Convert with debug output');
    print('  junitify -i test.json -o junit.xml --debug');
    print('');
    print('  # Convert with custom file relative path');
    print('  junitify -i test.json -o junit.xml -r /path/to/project');
    print('');
    print('  # Convert with timestamp option');
    print('  junitify -i test.json -o junit.xml -t now');
    print('  junitify -i test.json -o junit.xml -t none');
    print('  junitify -i test.json -o junit.xml -t 2024-01-01T12:00:00');
  }

  void _printError(String message) {
    print(message);
  }
}
