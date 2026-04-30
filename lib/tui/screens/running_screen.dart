import 'dart:async';
import 'dart:io';
import '../components/box.dart';
import '../components/log_tail.dart';
import '../components/status_bar.dart';
import '../input/key_events.dart';
import '../input/raw_terminal.dart';
import '../../core/devtools_detector.dart';
import '../../core/flutter_process.dart';
import '../../core/models/launch_config.dart';

enum RunningResult { backToPicker, quit }

class RunningScreen {
  final LaunchConfig config;
  final FlutterProcess process;
  final RawTerminal terminal;

  RunningScreen({
    required this.config,
    required this.process,
    required this.terminal,
  });

  static const _hints = [
    ('r', 'reload'),
    ('R', 'restart'),
    ('d', 'DevTools'),
    ('s', 'screenshot'),
    ('p', 'perf'),
    ('w', 'web'),
    ('q', 'stop+back'),
    ('Q', 'force kill'),
  ];

  final _log = LogTail(maxLines: 300);
  final _detector = DevToolsDetector();
  bool _running = true;

  Future<RunningResult> run() async {
    terminal.hideCursor();

    // Subscribe to process output.
    final outputSub = process.output.listen((line) {
      _log.addLine(line);
      _detector.feedLine(line);
      _render();
    });

    // Watch for process exit.
    final exitCompleter = Completer<int>();
    final exitSub = process.onExit.listen(exitCompleter.complete);

    _render();

    // Handle key input concurrently with process output.
    final result = await _handleKeys(exitCompleter.future);

    await outputSub.cancel();
    await exitSub.cancel();

    return result;
  }

  Future<RunningResult> _handleKeys(Future<int> exitFuture) async {
    final keyStream = keyEvents();
    late StreamSubscription<KeyEvent> keySub;
    final resultCompleter = Completer<RunningResult>();

    exitFuture.then((_) {
      if (!resultCompleter.isCompleted) {
        _running = false;
        _render();
        // Auto-return to picker after process exits naturally.
        resultCompleter.complete(RunningResult.backToPicker);
      }
    });

    keySub = keyStream.listen((key) async {
      if (resultCompleter.isCompleted) return;

      switch (key) {
        case CharKey(:final char) when char == 'r':
          process.sendKey('r');
        case CharKey(:final char) when char == 'R':
          process.sendKey('R');
        case CharKey(:final char) when char == 's':
          process.sendKey('s');
        case CharKey(:final char) when char == 'p':
          process.sendKey('p');
        case CharKey(:final char) when char == 'w':
          final url = _detector.webUrl;
          if (url != null) _openBrowser(url);
        case CharKey(:final char) when char == 'd':
          final url = _detector.devToolsUrl;
          if (url != null) _openBrowser(url);
        case CharKey(:final char) when char == 'q':
          await process.stop();
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(RunningResult.backToPicker);
          }
        case CharKey(:final char) when char == 'Q':
          process.kill();
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(RunningResult.backToPicker);
          }
        default:
          break;
      }
    });

    final result = await resultCompleter.future;
    await keySub.cancel();
    return result;
  }

  void _render() {
    final width = terminal.terminalWidth.clamp(60, 120);
    final maxRows = (terminal.terminalHeight - 8).clamp(4, 30);
    final status = _running ? '\x1B[32m● RUNNING\x1B[0m' : '\x1B[31m● STOPPED\x1B[0m';
    final title = '${config.name} ';

    final cmdPreview = [process.executable, ...process.arguments].join(' ');

    final lines = <String>[
      '  $cmdPreview',
      Box.divider(width),
      ..._log.render(maxRows),
      Box.divider(width),
      '  ${StatusBar.render(_hints)}',
    ];

    terminal.clearScreen();
    terminal.resetCursor();

    for (final line in Box.render(
      width: width,
      lines: lines,
      title: title,
      statusRight: status,
    )) {
      print(line);
    }
  }

  void _openBrowser(String url) {
    final isLinux = Platform.isLinux;
    final isMacOS = Platform.isMacOS;
    final isWindows = Platform.isWindows;

    if (isMacOS) {
      Process.run('open', [url]);
    } else if (isLinux) {
      Process.run('xdg-open', [url]);
    } else if (isWindows) {
      Process.run('start', [url], runInShell: true);
    }
  }
}
