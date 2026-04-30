import 'dart:async';
import 'package:path/path.dart' as p;
import '../components/box.dart';
import '../components/list.dart';
import '../components/status_bar.dart';
import '../input/key_events.dart';
import '../input/raw_terminal.dart';
import '../../core/models/launch_config.dart';
import '../../core/models/workspace_file.dart';

enum PickerResult { quit, runConfig, openAttach }

class PickerScreen {
  final WorkspaceFile workspace;
  final RawTerminal terminal;

  PickerScreen({required this.workspace, required this.terminal});

  static const _hints = [
    ('↑↓', 'navigate'),
    ('/', 'filter'),
    ('ENTER', 'run'),
    ('A', 'attach'),
    ('Q', 'quit'),
  ];

  String _filter = '';
  bool _filtering = false;

  /// Shows the picker. Returns the selected [LaunchConfig] or null on quit.
  Future<LaunchConfig?> run() async {
    terminal.hideCursor();

    while (true) {
      final filtered = _applyFilter();
      final list = ScrollableList(filtered.map((c) => c.name).toList());

      // Render loop
      final result = await _interact(list, filtered);

      switch (result) {
        case PickerResult.quit:
          return null;
        case PickerResult.runConfig:
          return filtered[list.cursor];
        case PickerResult.openAttach:
          // Attach mode — caller handles this; return null for now.
          return null;
      }
    }
  }

  Future<PickerResult> _interact(
      ScrollableList list, List<LaunchConfig> filtered) async {
    _render(list, filtered);

    await for (final key in keyEvents()) {
      if (_filtering) {
        switch (key) {
          case EscapeKey() || EnterKey():
            _filtering = false;
            terminal.showCursor();
          case BackspaceKey():
            if (_filter.isNotEmpty) {
              _filter = _filter.substring(0, _filter.length - 1);
            }
          case CharKey(:final char):
            _filter += char;
          default:
            break;
        }
        // Re-filter and rebuild list.
        final newFiltered = _applyFilter();
        final newList = ScrollableList(newFiltered.map((c) => c.name).toList());
        _render(newList, newFiltered);
        if (key is EnterKey) return PickerResult.runConfig;
        continue;
      }

      switch (key) {
        case ArrowUp():
          list.moveUp();
        case ArrowDown():
          list.moveDown();
        case EnterKey():
          return PickerResult.runConfig;
        case CharKey(:final char) when char == '/':
          _filtering = true;
          terminal.showCursor();
        case CharKey(:final char) when char.toLowerCase() == 'a':
          return PickerResult.openAttach;
        case CharKey(:final char) when char.toUpperCase() == 'Q':
          return PickerResult.quit;
        default:
          break;
      }
      _render(list, filtered);
    }

    return PickerResult.quit;
  }

  void _render(ScrollableList list, List<LaunchConfig> filtered) {
    final width = terminal.terminalWidth.clamp(60, 120);
    final maxRows = (terminal.terminalHeight - 8).clamp(4, 30);

    terminal.clearScreen();
    terminal.resetCursor();

    final workspaceName = p.basenameWithoutExtension(workspace.filePath);
    final title = '─ wsrun_cli ';
    final configCount = '${workspace.configs.length} configs';

    final lines = <String>[
      '  📂  $workspaceName          $configCount',
      Box.divider(width),
      '  🔍  ${_filtering ? _filter + '█' : (_filter.isEmpty ? 'type to filter...' : _filter)}',
      Box.divider(width),
      ...list.render(maxRows),
      Box.divider(width),
      '  ${StatusBar.render(_hints)}',
    ];

    for (final line in Box.render(width: width, lines: lines, title: title)) {
      print(line);
    }
  }

  List<LaunchConfig> _applyFilter() {
    if (_filter.isEmpty) return workspace.configs;
    final lower = _filter.toLowerCase();
    return workspace.configs
        .where((c) => c.name.toLowerCase().contains(lower))
        .toList();
  }
}
