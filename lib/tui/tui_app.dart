import 'dart:io';
import 'package:path/path.dart' as p;
import '../core/flutter_process.dart';
import '../core/folder_resolver.dart';
import '../core/models/launch_config.dart';
import '../core/models/workspace_file.dart';
import '../core/workspace_parser.dart';
import 'input/raw_terminal.dart';
import 'screens/picker_screen.dart';
import 'screens/running_screen.dart';

/// Top-level TUI application. Owns the terminal lifecycle and routes between screens.
class TuiApp {
  final String workingDirectory;
  final String? explicitWorkspacePath;

  TuiApp({
    required this.workingDirectory,
    this.explicitWorkspacePath,
  });

  final _terminal = RawTerminal();

  Future<void> run() async {
    _terminal.registerExitHandler();

    // Load workspace.
    final workspacePath = await WorkspaceParser.findWorkspaceFile(
      workingDirectory,
      explicitPath: explicitWorkspacePath,
      onChoose: _chooseWorkspace,
    );
    final workspace = WorkspaceParser.parse(workspacePath);

    _terminal.enableRawMode();

    try {
      await _pickerLoop(workspace);
    } finally {
      _terminal.disableRawMode();
      _terminal.showCursor();
    }
  }

  Future<void> _pickerLoop(WorkspaceFile workspace) async {
    while (true) {
      final picker = PickerScreen(workspace: workspace, terminal: _terminal);
      final selected = await picker.run();

      if (selected == null) break; // user quit

      await _runConfig(workspace, selected);
    }
  }

  Future<void> _runConfig(WorkspaceFile workspace, LaunchConfig config) async {
    final resolver = FolderResolver(workspace);
    final cwd = resolver.resolveCwd(config.cwd);
    final args = config.toCliArgs().map(resolver.resolve).toList();

    // Determine executable: flutter or dart based on type.
    final executable = config.type == 'flutter' || args.contains('lib/main.dart')
        ? 'flutter'
        : 'dart';

    final subCommand = executable == 'flutter' ? 'run' : 'run';
    final process = FlutterProcess(
      executable: executable,
      arguments: [subCommand, ...args],
      workingDirectory: cwd,
    );

    await process.start();

    final screen = RunningScreen(
      config: config,
      process: process,
      terminal: _terminal,
    );

    await screen.run();
    await process.dispose();
  }

  /// Prompts the user to choose among multiple workspace files using a simple
  /// numbered list (before raw mode is enabled, so we can use stdin.readLineSync).
  Future<String> _chooseWorkspace(List<String> paths) async {
    print('\nMultiple .code-workspace files found:');
    for (var i = 0; i < paths.length; i++) {
      print('  [${i + 1}] ${p.basename(paths[i])}');
    }
    stdout.write('Choose [1-${paths.length}]: ');
    final input = stdin.readLineSync() ?? '1';
    final idx = (int.tryParse(input.trim()) ?? 1) - 1;
    return paths[idx.clamp(0, paths.length - 1)];
  }
}
