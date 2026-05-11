import 'dart:async';
import 'dart:io';
import 'package:nocterm/nocterm.dart';
import 'package:path/path.dart' as p;
import '../core/browser_launcher.dart';
import '../core/devtools_detector.dart';
import '../core/flutter_process.dart';
import '../core/folder_resolver.dart';
import '../core/models/launch_config.dart';
import '../core/models/workspace_file.dart';
import '../core/workspace_parser.dart';
import '../core/zed_sync.dart';
import 'models/tui_attach_target.dart';
import 'models/tui_config.dart';
import 'models/tui_detected_urls.dart';
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
    this.startOnConnect = false,
  });

  final String workingDirectory;
  final String? explicitWorkspacePath;

  /// When true the TUI opens directly on the connect/attach screen.
  final bool startOnConnect;

  WorkspaceFile? _workspace;

  Future<void> run() async {
    final workspacePath = await WorkspaceParser.findWorkspaceFile(
      workingDirectory,
      explicitPath: explicitWorkspacePath,
      onChoose: _chooseWorkspace,
    );
    final workspace = WorkspaceParser.parse(workspacePath);
    _workspace = workspace;

    final configs = workspace.configs
        .map((c) => TuiConfig(name: c.name, type: c.type))
        .toList();

    await runApp(
      AppShell(
        configs: configs,
        onRunConfig: (tuiConfig) => _startProcess(workspace, tuiConfig),
        onAttachTarget: _attachProcess,
        onScanTargets: _scanTargets,
        startOnConnect: startOnConnect,
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
    final urlController = StreamController<TuiDetectedUrls>.broadcast();
    var attachWritten = false;

    final logStream = process.output.map((line) {
      if (detector.feedLine(line)) {
        String? attachPath;
        if (!attachWritten &&
            detector.vmServiceUrl != null &&
            config.program != null) {
          attachWritten = true;
          attachPath = ZedSync(workspace).writeAttach(
            label: config.name,
            resolvedCwd: cwd,
            program: config.program!,
            vmServiceUri: detector.vmServiceUrl!,
          );
        }
        urlController.add(TuiDetectedUrls(
          devToolsUrl: detector.devToolsUrl,
          vmServiceUrl: detector.vmServiceUrl,
          webUrl: detector.webUrl,
          zedAttachPath: attachPath,
        ));
      }
      return _classifyLine(line);
    }).asBroadcastStream();

    return TuiProcessHandle(
      logStream: logStream,
      urlStream: urlController.stream,
      sendKey: process.sendKey,
      stop: process.stop,
      dispose: () async {
        ZedSync(workspace).clearAttach();
        await urlController.close();
        await process.dispose();
      },
      openUrl: openInBrowser,
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

  /// Attaches to an already-running Flutter process identified by [target].
  ///
  /// Runs `flutter attach [--debug-url <url>]` in the config's resolved working
  /// directory so Flutter finds the right process.  When [debugUrl] is null,
  /// Flutter auto-scans for a running process from that directory.
  Future<TuiProcessHandle> _attachProcess(TuiAttachTarget target, String? debugUrl) async {
    final args = ['attach'];
    if (debugUrl != null) {
      args.add('--debug-url=$debugUrl');
    }

    final cwd = target.workingDirectory ?? workingDirectory;

    final process = FlutterProcess(
      executable: 'flutter',
      arguments: args,
      workingDirectory: cwd,
    );

    await process.start();

    final detector = DevToolsDetector();
    final urlController = StreamController<TuiDetectedUrls>.broadcast();

    final logStream = process.output.map((line) {
      if (detector.feedLine(line)) {
        urlController.add(TuiDetectedUrls(
          devToolsUrl: detector.devToolsUrl,
          vmServiceUrl: detector.vmServiceUrl,
          webUrl: detector.webUrl,
        ));
      }
      return _classifyLine(line);
    }).asBroadcastStream();

    return TuiProcessHandle(
      logStream: logStream,
      urlStream: urlController.stream,
      sendKey: process.sendKey,
      stop: process.stop,
      dispose: () async {
        await urlController.close();
        await process.dispose();
      },
      openUrl: openInBrowser,
    );
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

  /// Builds the attach target list from the workspace configs.
  ///
  /// Each config becomes one entry carrying its resolved working directory.
  /// This replaces the unreliable `flutter attach --list` mDNS scan.
  Future<List<TuiAttachTarget>> _scanTargets() async {
    final workspace = _workspace;
    if (workspace == null) return [];
    final resolver = FolderResolver(workspace);
    final targets = <TuiAttachTarget>[];
    for (final config in workspace.configs) {
      try {
        final cwd = resolver.resolveCwd(config.cwd);
        targets.add(TuiAttachTarget(
          pid: 0,
          name: config.name,
          workingDirectory: cwd,
        ));
      } catch (_) {
        // Skip configs whose workspaceFolder reference can't be resolved.
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
