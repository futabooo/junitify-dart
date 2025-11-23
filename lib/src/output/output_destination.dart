import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import '../common/error.dart';
import '../common/result.dart';

/// Interface for writing XML output.
abstract class OutputDestination {
  /// Writes an XML document to the destination.
  Future<Result<void, OutputError>> writeXml(XmlDocument document);
}

/// Writes XML to a file.
class FileOutputDestination implements OutputDestination {
  const FileOutputDestination(this.filePath);

  final String filePath;

  @override
  Future<Result<void, OutputError>> writeXml(XmlDocument document) async {
    try {
      final file = File(filePath);

      // Check parent directory exists
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      // Convert document to pretty-printed string
      // Pretty-print the whole document, but preserve whitespace (disable pretty) only inside <system-out> elements.
      // The preserveWhitespace callback returns true for <system-out> tags, so their contents are not reformatted.
      final xmlString = document.toXmlString(
        pretty: true,
        indent: '  ',
        preserveWhitespace: (node) =>
            node is XmlElement && node.name.local == 'system-out' ||
            node is XmlElement && node.name.local == 'failure',
      );

      // Write to file with UTF-8 encoding
      try {
        await file.writeAsString(xmlString, encoding: utf8);
        return const Success(null);
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 13) {
          // Permission denied
          return Failure(PermissionError(filePath));
        }
        return Failure(FileWriteError(filePath, e.message));
      } catch (e) {
        return Failure(FileWriteError(filePath, e.toString()));
      }
    } catch (e) {
      return Failure(
        FileWriteError(filePath, 'Unexpected error: ${e.toString()}'),
      );
    }
  }
}

/// Writes XML to standard output.
class StdoutOutputDestination implements OutputDestination {
  const StdoutOutputDestination();

  @override
  Future<Result<void, OutputError>> writeXml(XmlDocument document) async {
    try {
      // Convert document to string (pretty: false to preserve newlines in text content)
      final xmlString = document.toXmlString(pretty: false);

      // Write to stdout
      stdout.writeln(xmlString);

      return const Success(null);
    } catch (e) {
      return const Failure(
        FileWriteError('stdout', 'Failed to write to stdout'),
      );
    }
  }
}
