/// The phase where an error occurred in the conversion process.
enum ErrorPhase {
  /// Error occurred during input reading.
  input,

  /// Error occurred during JSON parsing.
  parsing,

  /// Error occurred during XML conversion.
  conversion,

  /// Error occurred during output writing.
  output,
}

/// Base class for all application errors.
sealed class AppError {
  const AppError(this.message, [this.stackTrace]);

  final String message;
  final StackTrace? stackTrace;

  /// Returns the phase where this error occurred.
  ErrorPhase get phase;

  @override
  String toString() => message;
}

/// Error that occurred during input reading phase.
final class InputPhaseError extends AppError {
  InputPhaseError(this.cause) : super('Input error: ${cause.message}');

  final InputError cause;

  @override
  ErrorPhase get phase => ErrorPhase.input;
}

/// Error that occurred during parsing phase.
final class ParsingPhaseError extends AppError {
  ParsingPhaseError(this.cause) : super('Parsing error: ${cause.message}');

  final ParseError cause;

  @override
  ErrorPhase get phase => ErrorPhase.parsing;
}

/// Error that occurred during output phase.
final class OutputPhaseError extends AppError {
  OutputPhaseError(this.cause) : super('Output error: ${cause.message}');

  final OutputError cause;

  @override
  ErrorPhase get phase => ErrorPhase.output;
}

// Input Errors

/// Base class for input-related errors.
sealed class InputError {
  const InputError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Error when a file is not found.
final class FileNotFoundError extends InputError {
  const FileNotFoundError(this.path) : super('File not found: $path');

  final String path;
}

/// Error when reading a file fails.
final class FileReadError extends InputError {
  const FileReadError(this.path, this.reason)
    : super('Failed to read file $path: $reason');

  final String path;
  final String reason;
}

/// Error when encoding is invalid.
final class EncodingError extends InputError {
  const EncodingError(String reason) : super('Encoding error: $reason');
}

// Parse Errors

/// Base class for parsing-related errors.
sealed class ParseError {
  const ParseError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Error when JSON syntax is invalid.
final class JsonSyntaxError extends ParseError {
  const JsonSyntaxError(super.message, {this.line, this.column});

  final int? line;
  final int? column;

  @override
  String toString() {
    if (line != null && column != null) {
      return 'JSON syntax error at line $line, column $column: $message';
    }
    return 'JSON syntax error: $message';
  }
}

/// Error when a field format is invalid.
final class InvalidFormatError extends ParseError {
  const InvalidFormatError(this.field, String reason)
    : super('Invalid field "$field": $reason');

  final String field;
}

/// Error when a required field is missing.
final class MissingFieldError extends ParseError {
  const MissingFieldError(this.field) : super('Required field missing: $field');

  final String field;
}

// Output Errors

/// Base class for output-related errors.
sealed class OutputError {
  const OutputError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Error when writing to a file fails.
final class FileWriteError extends OutputError {
  const FileWriteError(this.path, this.reason)
    : super('Failed to write file $path: $reason');

  final String path;
  final String reason;
}

/// Error when permission is denied.
final class PermissionError extends OutputError {
  const PermissionError(this.path) : super('Permission denied: $path');

  final String path;
}
