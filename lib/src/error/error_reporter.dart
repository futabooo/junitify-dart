import 'dart:io';

import '../common/error.dart';

/// Interface for error reporting and logging.
abstract class ErrorReporter {
  /// Reports an error to stderr.
  void reportError(AppError error, {bool includeStackTrace = false});

  /// Outputs a debug message.
  void debug(String message);

  /// Outputs an info message.
  void info(String message);
}

/// Default implementation of ErrorReporter.
class ConsoleErrorReporter implements ErrorReporter {
  ConsoleErrorReporter({this.debugMode = false});

  final bool debugMode;

  @override
  void reportError(AppError error, {bool includeStackTrace = false}) {
    final phaseStr = _phaseToString(error.phase);
    stderr.writeln('[$phaseStr] Error: ${error.message}');

    if ((includeStackTrace || debugMode) && error.stackTrace != null) {
      stderr.writeln('Stack trace:');
      stderr.writeln(error.stackTrace);
    }
  }

  @override
  void debug(String message) {
    if (debugMode) {
      stderr.writeln('[DEBUG] $message');
    }
  }

  @override
  void info(String message) {
    stdout.writeln('[INFO] $message');
  }

  String _phaseToString(ErrorPhase phase) {
    return switch (phase) {
      ErrorPhase.input => 'INPUT',
      ErrorPhase.parsing => 'PARSING',
      ErrorPhase.conversion => 'CONVERSION',
      ErrorPhase.output => 'OUTPUT',
    };
  }
}
