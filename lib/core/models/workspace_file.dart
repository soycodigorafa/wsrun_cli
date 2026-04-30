import 'launch_config.dart';
import 'workspace_folder.dart';

/// Aggregate of a fully parsed `.code-workspace` file.
class WorkspaceFile {
  /// Absolute path to the `.code-workspace` file.
  final String filePath;
  final List<WorkspaceFolder> folders;
  final List<LaunchConfig> configs;

  const WorkspaceFile({
    required this.filePath,
    required this.folders,
    required this.configs,
  });

  @override
  String toString() =>
      'WorkspaceFile(folders: ${folders.length}, configs: ${configs.length})';
}
