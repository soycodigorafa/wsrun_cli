import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../components/box.dart';
import '../components/list.dart';
import '../components/status_bar.dart';
import '../input/key_events.dart';
import '../input/raw_terminal.dart';

/// Represents a discovered running Flutter process.
class FlutterAttachTarget {
  final int pid;
  final String name;
  final String? device;
  final String? vmServiceUri;

  const FlutterAttachTarget({
    required this.pid,
    required this.name,
    this.device,
    this.vmServiceUri,
  });

  String get displayLine {
    final parts = [name, if (device != null) device!, if (vmServiceUri != null) vmServiceUri!];
    return parts.join('  │  ');
  }
}

class ConnectScreen {
  final RawTerminal terminal;

  ConnectScreen({required this.terminal});

  static const _hints = [
    ('↑↓', 'navigate'),
    ('ENTER', 'connect'),
    ('Q', 'quit'),
  ];

  Future<FlutterAttachTarget?> run() async {
    terminal.hideCursor();
    _renderScanning();

    final targets = await _scanProcesses();

    if (targets.isEmpty) {
      _renderEmpty();
      await Future.delayed(const Duration(seconds: 2));
      return null;
    }

    return await _interact(targets);
  }

  Future<FlutterAttachTarget?> _interact(List<FlutterAttachTarget> targets) async {
    final list = ScrollableList(targets.map((t) => t.displayLine).toList());
    _render(list, targets);

    await for (final key in keyEvents()) {
      switch (key) {
        case ArrowUp():
          list.moveUp();
        case ArrowDown():
          list.moveDown();
        case EnterKey():
          return targets[list.cursor];
        case CharKey(:final char) when char.toUpperCase() == 'Q':
          return null;
        default:
          break;
      }
      _render(list, targets);
    }
    return null;
  }

  /// Scans for running Flutter processes using `flutter attach --list`.
  Future<List<FlutterAttachTarget>> _scanProcesses() async {
    try {
      final result = await Process.run(
        'flutter',
        ['attach', '--list'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      return _parseFlutterList(result.stdout as String);
    } catch (_) {
      return [];
    }
  }

  List<FlutterAttachTarget> _parseFlutterList(String output) {
    final targets = <FlutterAttachTarget>[];
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('No ')) continue;
      // Basic parse: PID  AppName  DeviceName  ws://...
      final parts = trimmed.split(RegExp(r'\s{2,}'));
      if (parts.length >= 2) {
        final pid = int.tryParse(parts[0]) ?? 0;
        targets.add(FlutterAttachTarget(
          pid: pid,
          name: parts.length > 1 ? parts[1] : trimmed,
          device: parts.length > 2 ? parts[2] : null,
          vmServiceUri: parts.length > 3 ? parts[3] : null,
        ));
      }
    }
    return targets;
  }

  void _renderScanning() {
    final width = terminal.terminalWidth.clamp(60, 120);
    terminal.clearScreen();
    terminal.resetCursor();
    for (final line in Box.render(
      width: width,
      lines: ['  Scanning for running Flutter processes...'],
      title: '─ wsrun_cli — connect ',
    )) {
      print(line);
    }
  }

  void _renderEmpty() {
    final width = terminal.terminalWidth.clamp(60, 120);
    terminal.clearScreen();
    terminal.resetCursor();
    for (final line in Box.render(
      width: width,
      lines: ['  No running Flutter processes found.'],
      title: '─ wsrun_cli — connect ',
    )) {
      print(line);
    }
  }

  void _render(ScrollableList list, List<FlutterAttachTarget> targets) {
    final width = terminal.terminalWidth.clamp(60, 120);
    final maxRows = (terminal.terminalHeight - 8).clamp(4, 20);
    terminal.clearScreen();
    terminal.resetCursor();
    for (final line in Box.render(
      width: width,
      lines: [
        ...list.render(maxRows),
        Box.divider(width),
        '  ${StatusBar.render(_hints)}',
      ],
      title: '─ wsrun_cli — connect ',
    )) {
      print(line);
    }
  }
}
