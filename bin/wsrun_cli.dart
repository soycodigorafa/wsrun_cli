import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import '../lib/core/workspace_parser.dart';
import '../lib/core/folder_resolver.dart';
import '../lib/tui/tui_app.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'workspace',
      abbr: 'w',
      help: 'Path to a .code-workspace file.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  // Sub-commands
  final runParser = ArgParser()
    ..addOption('index', abbr: 'i', help: 'Run config by index.')
    ..addFlag('help', abbr: 'h', negatable: false);

  parser
    ..addCommand('run', runParser)
    ..addCommand('list')
    ..addCommand('info')
    ..addCommand('attach');

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final cwd = Directory.current.path;
  final workspacePath = args['workspace'] as String?;

  final command = args.command;

  try {
    if (command == null || command.name == null) {
      // Default: interactive TUI
      await TuiApp(
        workingDirectory: cwd,
        explicitWorkspacePath: workspacePath,
      ).run();
      return;
    }

    switch (command.name) {
      case 'list':
        await _cmdList(cwd, workspacePath);

      case 'info':
        await _cmdInfo(cwd, workspacePath);

      case 'run':
        final name = command.rest.isNotEmpty ? command.rest.join(' ') : null;
        final indexStr = command['index'] as String?;
        await _cmdRun(cwd, workspacePath, name: name, index: indexStr != null ? int.parse(indexStr) : null);

      case 'attach':
        // Open the TUI connect screen to attach to a running Flutter process.
        await TuiApp(
          workingDirectory: cwd,
          explicitWorkspacePath: workspacePath,
        ).run();

      default:
        stderr.writeln('Unknown command: ${command.name}');
        _printUsage(parser);
        exit(1);
    }
  } on StateError catch (e) {
    stderr.writeln('error: ${e.message}');
    exit(1);
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message}: ${e.path}');
    exit(1);
  }
}

Future<void> _cmdList(String cwd, String? workspacePath) async {
  final path = await WorkspaceParser.findWorkspaceFile(cwd, explicitPath: workspacePath);
  final workspace = WorkspaceParser.parse(path);

  print('\n  ${p.basenameWithoutExtension(path)}  (${workspace.configs.length} configs)\n');
  print('  #   Name');
  print('  ─── ────────────────────────────────────────');
  for (var i = 0; i < workspace.configs.length; i++) {
    print('  ${i.toString().padLeft(3)}  ${workspace.configs[i].name}');
  }
  print('');
}

Future<void> _cmdInfo(String cwd, String? workspacePath) async {
  final path = await WorkspaceParser.findWorkspaceFile(cwd, explicitPath: workspacePath);
  final workspace = WorkspaceParser.parse(path);

  print('\n  Workspace : ${workspace.filePath}');
  print('  Folders   : ${workspace.folders.length}');
  for (final f in workspace.folders) {
    print('    • ${f.name}  →  ${f.path}');
  }
  print('  Configs   : ${workspace.configs.length}');
  for (final c in workspace.configs) {
    print('    • [${c.type}] ${c.name}');
  }
  print('');
}

Future<void> _cmdRun(String cwd, String? workspacePath,
    {String? name, int? index}) async {
  final path = await WorkspaceParser.findWorkspaceFile(cwd, explicitPath: workspacePath);
  final workspace = WorkspaceParser.parse(path);
  final resolver = FolderResolver(workspace);

  if (workspace.configs.isEmpty) {
    stderr.writeln('No launch configurations found.');
    exit(1);
  }

  final config = () {
    if (index != null) return workspace.configs[index];
    if (name != null) {
      return workspace.configs.firstWhere(
        (c) => c.name == name,
        orElse: () {
          stderr.writeln('Config not found: "$name"');
          exit(1);
        },
      );
    }
    return workspace.configs.first;
  }();

  final resolvedCwd = resolver.resolveCwd(config.cwd);
  final args = config.toCliArgs().map(resolver.resolve).toList();
  final executable = 'flutter';

  print('Running: $executable run ${args.join(' ')}');
  print('In: $resolvedCwd\n');

  final process = await Process.start(
    executable,
    ['run', ...args],
    workingDirectory: resolvedCwd,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  exit(exitCode);
}

void _printUsage(ArgParser parser) {
  print('''
wsrun — Run VS Code workspace launch configs from any terminal.

Usage:
  wsrun                           Interactive TUI picker (default)
  wsrun list                      Print all launch configs
  wsrun run "Config Name"         Run by name
  wsrun run --index 0             Run by index
  wsrun attach                    Connect to a running Flutter process
  wsrun info                      Show workspace summary

Options:
${parser.usage}
''');
}
