/// Configuration for the CLI application.
class CliConfig {
  const CliConfig({
    this.inputPath,
    this.outputPath,
    this.showHelp = false,
    this.showVersion = false,
    this.debugMode = false,
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

  @override
  String toString() =>
      'CliConfig('
      'input: ${inputPath ?? "stdin"}, '
      'output: ${outputPath ?? "stdout"}, '
      'debug: $debugMode'
      ')';
}
