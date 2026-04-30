import 'package:path/path.dart' as p;
import 'models/workspace_file.dart';

/// Resolves `${workspaceFolder:NAME}` variables in strings to absolute paths.
class FolderResolver {
  final WorkspaceFile workspace;

  FolderResolver(this.workspace);

  static final _varRegex = RegExp(r'\$\{workspaceFolder:([^}]+)\}');

  /// Resolves all `${workspaceFolder:NAME}` occurrences in [value].
  /// Throws [ArgumentError] if a referenced folder name is not found.
  String resolve(String value) {
    return value.replaceAllMapped(_varRegex, (match) {
      final name = match.group(1)!;
      final folder = workspace.folders.firstWhere(
        (f) => f.name == name,
        orElse: () => throw ArgumentError(
          'workspaceFolder "$name" not found in workspace. '
          'Available: ${workspace.folders.map((f) => f.name).join(', ')}',
        ),
      );
      final workspaceDir = p.dirname(workspace.filePath);
      return p.normalize(p.join(workspaceDir, folder.path));
    });
  }

  /// Resolves the `cwd` of a launch config, returning an absolute path.
  /// Falls back to the workspace file's directory if cwd is null.
  String resolveCwd(String? cwd) {
    if (cwd == null) return p.dirname(workspace.filePath);
    final resolved = resolve(cwd);
    if (p.isAbsolute(resolved)) return resolved;
    return p.normalize(p.join(p.dirname(workspace.filePath), resolved));
  }
}
