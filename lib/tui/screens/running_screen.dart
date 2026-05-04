import 'dart:async';
import 'package:nocterm/nocterm.dart';
import '../models/tui_config.dart';
import '../models/tui_log_line.dart';
import '../components/log_viewer.dart';
import '../components/status_bar.dart';
import '../utils/string_utils.dart';

class RunningScreen extends StatefulComponent {
  const RunningScreen({
    required this.config,
    required this.logStream,
    required this.onSendKey,
    required this.onStop,
    required this.onBack,
    super.key,
  });

  final TuiConfig config;
  final Stream<TuiLogLine> logStream;
  final void Function(String key) onSendKey;
  final Future<void> Function() onStop;
  final void Function() onBack;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  final List<TuiLogLine> _lines = [];
  StreamSubscription<TuiLogLine>? _sub;
  bool _running = true;

  static const _maxLines = 300;

  static const _hints = [
    ('r', 'reload'),
    ('R', 'restart'),
    ('s', 'screenshot'),
    ('p', 'perf'),
    ('q', 'stop+back'),
    ('Q', 'force kill'),
  ];

  @override
  void initState() {
    super.initState();
    _sub = component.logStream.listen(
      (line) {
        if (!mounted) return;
        setState(() {
          _lines.add(line);
          if (_lines.length > _maxLines) _lines.removeAt(0);
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _running = false);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) component.onBack();
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final statusColor = _running ? Colors.brightGreen : Colors.red;
    final statusLabel = _running ? '● RUNNING' : '● STOPPED';

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final char = event.character;
        if (char == 'r') { component.onSendKey('r'); return true; }
        if (char == 'R') { component.onSendKey('R'); return true; }
        if (char == 's') { component.onSendKey('s'); return true; }
        if (char == 'p') { component.onSendKey('p'); return true; }
        if (char == 'q') {
          component.onStop().then((_) { if (mounted) component.onBack(); });
          return true;
        }
        if (char == 'Q') {
          component.onSendKey('Q');
          if (mounted) component.onBack();
          return true;
        }
        if (event.modifiers.ctrl && event.logicalKey == LogicalKey.keyC) {
          shutdownApp();
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.brightBlack),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Text(
                    '  ${stripEmojis(component.config.name)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightWhite),
                  ),
                  Expanded(child: SizedBox()),
                  Text(statusLabel, style: TextStyle(color: statusColor)),
                  Text('  '),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: LogViewer(lines: _lines),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: StatusBar(hints: _hints),
            ),
          ],
        ),
      ),
    );
  }
}
