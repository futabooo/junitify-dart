/// Configuration for the CLI application.
class CliConfig {
  const CliConfig({
    this.inputPath,
    this.outputPath,
    this.showHelp = false,
    this.showVersion = false,
    this.debugMode = false,
    this.fileRelativeTo = '.',
    this.timestampOption,
  });

  /// Path to input JSON file (null means stdin).
  final String? inputPath;

  /// Path to output XML file (null means stdout).
  final String? outputPath;

  /// Whether to show help message.
  final bool showHelp;

  /// Whether to show version information.
  final bool showVersion;

  /// Whether to enable debug mode.
  final bool debugMode;

  /// The relative path to calculate the path defined in the 'file' element in the test from.
  /// Defaults to '.' (current working directory).
  /// If null or empty, absolute paths are maintained.
  final String? fileRelativeTo;

  /// Timestamp option value (`now`, `none`, or `yyyy-MM-ddTHH:mm:ss` format).
  /// If null, timestamp is determined based on inputPath or current time.
  final String? timestampOption;

  @override
  String toString() =>
      'CliConfig('
      'input: ${inputPath ?? "stdin"}, '
      'output: ${outputPath ?? "stdout"}, '
      'debug: $debugMode, '
      'fileRelativeTo: ${fileRelativeTo ?? "null"}'
      ')';
}
