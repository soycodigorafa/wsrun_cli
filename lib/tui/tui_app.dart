import 'dart:convert';
import 'dart:io';
import 'package:nocterm/nocterm.dart';
import 'package:path/path.dart' as p;
import '../core/devtools_detector.dart';
import '../core/flutter_process.dart';
import '../core/folder_resolver.dart';
import '../core/models/launch_config.dart';
import '../core/models/workspace_file.dart';
import '../core/workspace_parser.dart';
import 'models/tui_attach_target.dart';
import 'models/tui_config.dart';
import 'models/tui_log_line.dart';
import 'models/tui_process_handle.dart';
import 'screens/app_shell.dart';

/// Bridges [lib/core] with the nocterm TUI.
///
/// Finds the workspace file (before entering raw mode), converts core types to
/// TUI model types, then calls [runApp] with a fully wired [AppShell].
class TuiApp {
  TuiApp({
    required this.workingDirectory,
    this.explicitWorkspacePath,
  });

  final String workingDirectory;
  final String? explicitWorkspacePath;

  Future<void> run() async {
    final workspacePath = await WorkspaceParser.findWorkspaceFile(
      workingDirectory,
      explicitPath: explicitWorkspacePath,
      onChoose: _chooseWorkspace,
    );
    final workspace = WorkspaceParser.parse(workspacePath);

    final configs = workspace.configs
        .map((c) => TuiConfig(name: c.name, type: c.type))
        .toList();

    await runApp(
      AppShell(
        configs: configs,
        onRunConfig: (tuiConfig) => _startProcess(workspace, tuiConfig),
        onScanTargets: _scanTargets,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Process management

  Future<TuiProcessHandle> _startProcess(
    WorkspaceFile workspace,
    TuiConfig tuiConfig,
  ) async {
    final config = workspace.configs.firstWhere((c) => c.name == tuiConfig.name);
    final resolver = FolderResolver(workspace);
    final cwd = resolver.resolveCwd(config.cwd);
    final cliArgs = config.toCliArgs().map(resolver.resolve).toList();

    final executable = _executableFor(config);
    final process = FlutterProcess(
      executable: executable,
      arguments: ['run', ...cliArgs],
      workingDirectory: cwd,
    );

    await process.start();

    final detector = DevToolsDetector();
    final logStream = process.output.map((line) {
      detector.feedLine(line);
      return _classifyLine(line);
    }).asBroadcastStream();

    return TuiProcessHandle(
      logStream: logStream,
      sendKey: process.sendKey,
      stop: process.stop,
      dispose: process.dispose,
    );
  }

  String _executableFor(LaunchConfig config) {
    if (config.type == 'flutter') return 'flutter';
    final args = config.toCliArgs();
    if (args.any((a) => a.endsWith('.dart') || a == 'lib/main.dart')) {
      return 'flutter';
    }
    return 'dart';
  }

  TuiLogLine _classifyLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('exception') || lower.contains('fatal')) {
      return TuiLogLine.error(line);
    }
    if (lower.contains('warning') || lower.contains('warn') || lower.contains('w/flutter')) {
      return TuiLogLine.warn(line);
    }
    return TuiLogLine(line);
  }

  // ---------------------------------------------------------------------------
  // Connect / attach scanning

  Future<List<TuiAttachTarget>> _scanTargets() async {
    try {
      final result = await Process.run(
        'flutter',
        ['attach', '--list'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      return _parseFlutterAttachList(result.stdout as String);
    } catch (_) {
      return [];
    }
  }

  List<TuiAttachTarget> _parseFlutterAttachList(String output) {
    final targets = <TuiAttachTarget>[];
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('No ')) continue;
      final parts = trimmed.split(RegExp(r'\s{2,}'));
      if (parts.length >= 2) {
        final pid = int.tryParse(parts[0]) ?? 0;
        targets.add(TuiAttachTarget(
          pid: pid,
          name: parts.length > 1 ? parts[1] : trimmed,
          device: parts.length > 2 ? parts[2] : null,
          vmServiceUri: parts.length > 3 ? parts[3] : null,
        ));
      }
    }
    return targets;
  }

  // ---------------------------------------------------------------------------
  // Pre-TUI workspace chooser (runs before raw mode is active)

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
