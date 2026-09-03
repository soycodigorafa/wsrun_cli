import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'models/launch_config.dart';
import 'models/workspace_file.dart';
import 'models/workspace_folder.dart';

/// Finds, reads, and parses `.code-workspace` files (JSONC format).
class WorkspaceParser {
  /// Finds the workspace file to use.
  ///
  /// If [explicitPath] is given, uses that. Otherwise scans [directory] for
  /// `.code-workspace` files. If multiple are found, [onChoose] is called with
  /// the list of paths and must return the chosen path.
  static Future<String> findWorkspaceFile(
    String directory, {
    String? explicitPath,
    Future<String> Function(List<String> paths)? onChoose,
  }) async {
    if (explicitPath != null) {
      if (!File(explicitPath).existsSync()) {
        throw FileSystemException('Workspace file not found', explicitPath);
      }
      return explicitPath;
    }

    final dir = Directory(directory);
    final files = dir
        .listSync(followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.code-workspace'))
        .map((f) => f.path)
        .toList();

    if (files.isEmpty) {
      throw StateError(
        'No .code-workspace file found in $directory.\n'
        'Use --workspace <path> to specify one explicitly.',
      );
    }
    if (files.length == 1) return files.first;

    if (onChoose == null) return files.first;
    return onChoose(files);
  }

  /// Parses a `.code-workspace` file at [filePath] into a [WorkspaceFile].
  static WorkspaceFile parse(String filePath) {
    final raw = File(filePath).readAsStringSync();
    final json = _stripTrailingCommas(_stripComments(raw));
    final Map<String, dynamic> data =
        jsonDecode(json) as Map<String, dynamic>;

    final folders = (data['folders'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(WorkspaceFolder.fromJson)
        .toList();

    final launchSection = data['launch'] as Map<String, dynamic>?;
    final configsRaw = (launchSection?['configurations'] as List<dynamic>?)
        ?? (data['configurations'] as List<dynamic>?)
        ?? [];

    final configs = configsRaw
        .cast<Map<String, dynamic>>()
        .map(LaunchConfig.fromJson)
        .toList();

    return WorkspaceFile(
      filePath: p.absolute(filePath),
      folders: folders,
      configs: configs,
    );
  }

  /// Public test-only access to comment stripping logic.
  // ignore: prefer_constructors_over_static_methods
  static String stripCommentsForTest(String source) => _stripComments(source);

  /// Public test-only access to trailing comma stripping logic.
  // ignore: prefer_constructors_over_static_methods
  static String stripTrailingCommasForTest(String source) =>
      _stripTrailingCommas(source);

  /// Strips `//` line comments and `/* */` block comments from JSON text.
  static String _stripComments(String source) {
    final buf = StringBuffer();
    var i = 0;
    final len = source.length;

    while (i < len) {
      // Inside string literals — copy verbatim until closing quote.
      if (source[i] == '"') {
        buf.write('"');
        i++;
        while (i < len) {
          if (source[i] == '\\' && i + 1 < len) {
            buf.write(source[i]);
            buf.write(source[i + 1]);
            i += 2;
          } else if (source[i] == '"') {
            buf.write('"');
            i++;
            break;
          } else {
            buf.write(source[i]);
            i++;
          }
        }
        continue;
      }

      // Line comment `//`
      if (i + 1 < len && source[i] == '/' && source[i + 1] == '/') {
        while (i < len && source[i] != '\n') {
          i++;
        }
        continue;
      }

      // Block comment `/* */`
      if (i + 1 < len && source[i] == '/' && source[i + 1] == '*') {
        i += 2;
        while (i + 1 < len && !(source[i] == '*' && source[i + 1] == '/')) {
          i++;
        }
        i += 2; // skip closing */
        continue;
      }

      buf.write(source[i]);
      i++;
    }

    return buf.toString();
  }

  /// Strips trailing commas before `}` or `]`, which VS Code's JSONC allows
  /// but Dart's [jsonDecode] rejects. Expects comments already stripped, so
  /// only whitespace can separate a comma from its closing bracket.
  static String _stripTrailingCommas(String source) {
    final buf = StringBuffer();
    var i = 0;
    final len = source.length;

    while (i < len) {
      if (source[i] == '"') {
        buf.write('"');
        i++;
        while (i < len) {
          if (source[i] == '\\' && i + 1 < len) {
            buf.write(source[i]);
            buf.write(source[i + 1]);
            i += 2;
          } else if (source[i] == '"') {
            buf.write('"');
            i++;
            break;
          } else {
            buf.write(source[i]);
            i++;
          }
        }
        continue;
      }

      if (source[i] == ',') {
        var j = i + 1;
        while (j < len && _isJsonWhitespace(source[j])) {
          j++;
        }
        if (j < len && (source[j] == '}' || source[j] == ']')) {
          i++;
          continue;
        }
      }

      buf.write(source[i]);
      i++;
    }

    return buf.toString();
  }

  static bool _isJsonWhitespace(String ch) =>
      ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r';
}
