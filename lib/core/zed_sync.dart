import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'folder_resolver.dart';
import 'models/workspace_file.dart';

/// Translates a [WorkspaceFile]'s launch configs into a `.zed/debug.json`
/// so that Zed's DAP debugger can be driven directly from a `.code-workspace`
/// file without duplicating configuration.
class ZedSync {
  final WorkspaceFile workspace;
  final FolderResolver resolver;

  ZedSync(this.workspace) : resolver = FolderResolver(workspace);

  /// Builds the list of Zed debug config objects from the workspace configs.
  ///
  /// Configs without a `program` are returned in [skipped].
  List<Map<String, dynamic>> toZedConfigs({List<String>? skipped}) {
    final result = <Map<String, dynamic>>[];

    for (final config in workspace.configs) {
      if (config.program == null) {
        skipped?.add(config.name);
        continue;
      }

      final resolvedCwd = resolver.resolveCwd(config.cwd);

      // VS Code uses "dart" for both Dart and Flutter projects. Zed's adapter
      // distinguishes them: "flutter" → `flutter debug_adapter`,
      // "dart" → `dart debug_adapter`. Auto-promote to "flutter" when the
      // resolved cwd looks like a Flutter project.
      final effectiveType =
          config.type == 'dart' && _isFlutterProject(resolvedCwd)
              ? 'flutter'
              : config.type;

      final entry = <String, dynamic>{
        'label': config.name,
        'adapter': 'Dart',
        'request': config.request,
        'type': effectiveType,
        'program': config.program!,
        'cwd': resolvedCwd,
      };

      if (config.args.isNotEmpty) entry['args'] = config.args;

      result.add(entry);
    }

    return result;
  }

  /// Writes `.zed/debug.json` next to the workspace file and returns the
  /// written path. Creates the `.zed/` directory if it does not exist.
  ///
  /// Returns the written path and populates [skipped] with config names that
  /// were omitted because they had no `program` field.
  String write({List<String>? skipped}) {
    final workspaceDir = p.dirname(workspace.filePath);
    final zedDir = Directory(p.join(workspaceDir, '.zed'));
    if (!zedDir.existsSync()) zedDir.createSync();

    final outPath = p.join(zedDir.path, 'debug.json');
    final configs = toZedConfigs(skipped: skipped);
    final encoder = JsonEncoder.withIndent('  ');
    File(outPath).writeAsStringSync(encoder.convert(configs));

    return outPath;
  }

  /// Returns true if [projectDir] contains a `pubspec.yaml` that references
  /// the Flutter SDK or the flutter package — i.e. it is a Flutter project.
  static bool _isFlutterProject(String projectDir) {
    final pubspec = File(p.join(projectDir, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return false;
    return pubspec.readAsStringSync().contains('flutter:');
  }
}
