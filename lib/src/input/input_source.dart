import 'dart:convert';
import 'dart:io';

import '../common/error.dart';
import '../common/result.dart';

/// Interface for reading JSON input.
abstract class InputSource {
  /// Reads JSON input as a string.
  Future<Result<String, InputError>> readJson();
}

/// Reads JSON from a file.
class FileInputSource implements InputSource {
  const FileInputSource(this.filePath);

  final String filePath;

  @override
  Future<Result<String, InputError>> readJson() async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        return Failure(FileNotFoundError(filePath));
      }

      // Read file as UTF-8 string
      try {
        final content = await file.readAsString(encoding: utf8);
        return Success(content);
      } on FormatException catch (e) {
        return Failure(EncodingError('Invalid UTF-8 encoding: ${e.message}'));
      } catch (e) {
        return Failure(FileReadError(filePath, e.toString()));
      }
    } catch (e) {
      return Failure(
        FileReadError(filePath, 'Unexpected error: ${e.toString()}'),
      );
    }
  }
}

/// Reads JSON from standard input.
class StdinInputSource implements InputSource {
  const StdinInputSource();

  @override
  Future<Result<String, InputError>> readJson() async {
    try {
      final lines = <String>[];

      // Read all lines from stdin
      await for (final line in stdin.transform(utf8.decoder)) {
        lines.add(line);
      }

      final content = lines.join('\n');

      if (content.isEmpty) {
        return const Failure(EncodingError('No input provided'));
      }

      return Success(content);
    } on FormatException catch (e) {
      return Failure(EncodingError('Invalid UTF-8 encoding: ${e.message}'));
    } catch (e) {
      return Failure(EncodingError('Failed to read from stdin: $e'));
    }
  }
}
