import 'dart:async';
import 'package:nocterm/nocterm.dart';
import '../models/tui_config.dart';
import '../models/tui_detected_urls.dart';
import '../models/tui_log_line.dart';
import '../components/log_viewer.dart';
import '../components/status_bar.dart';
import '../utils/string_utils.dart';

class RunningScreen extends StatefulComponent {
  const RunningScreen({
    required this.config,
    required this.logStream,
    required this.urlStream,
    required this.onSendKey,
    required this.onStop,
    required this.onOpenUrl,
    required this.onBack,
    super.key,
  });

  final TuiConfig config;
  final Stream<TuiLogLine> logStream;
  final Stream<TuiDetectedUrls> urlStream;
  final void Function(String key) onSendKey;
  final Future<void> Function() onStop;
  final Future<void> Function(String url) onOpenUrl;
  final void Function() onBack;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  final List<TuiLogLine> _lines = [];
  StreamSubscription<TuiLogLine>? _logSub;
  StreamSubscription<TuiDetectedUrls>? _urlSub;
  bool _running = true;
  TuiDetectedUrls _urls = const TuiDetectedUrls();

  static const _maxLines = 300;

  List<(String, String)> get _hints {
    final hints = <(String, String)>[
      ('r', 'reload'),
      ('R', 'restart'),
      ('s', 'screenshot'),
      ('p', 'perf'),
    ];
    if (_urls.devToolsUrl != null) hints.add(('d', 'devtools'));
    if (_urls.webUrl != null) hints.add(('b', 'browser'));
    hints.addAll([
      ('q', 'stop+back'),
      ('Q', 'force kill'),
    ]);
    return hints;
  }

  @override
  void initState() {
    super.initState();
    _logSub = component.logStream.listen(
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

    _urlSub = component.urlStream.listen((urls) {
      if (!mounted) return;
      setState(() => _urls = urls);
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _urlSub?.cancel();
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
        if (char == 'd' && _urls.devToolsUrl != null) {
          component.onOpenUrl(_urls.devToolsUrl!);
          return true;
        }
        if (char == 'b' && _urls.webUrl != null) {
          component.onOpenUrl(_urls.webUrl!);
          return true;
        }
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
            if (_urls.hasAny) ...[
              _UrlRow(urls: _urls),
              Container(
                decoration: BoxDecoration(
                  border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
                ),
              ),
            ],
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

/// Compact row showing detected URLs with their shortcut keys highlighted.
class _UrlRow extends StatelessComponent {
  const _UrlRow({required this.urls});
  final TuiDetectedUrls urls;

  @override
  Component build(BuildContext context) {
    final children = <Component>[
      Text('  ', style: TextStyle(color: Colors.brightBlack)),
    ];

    if (urls.devToolsUrl != null) {
      children.addAll([
        Text('[d] ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightCyan)),
        Text('DevTools ', style: TextStyle(color: Colors.brightBlack)),
        Text(urls.devToolsUrl!, style: TextStyle(color: Colors.cyan)),
        Text('   '),
      ]);
    }

    if (urls.webUrl != null) {
      children.addAll([
        Text('[b] ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightCyan)),
        Text('Web ', style: TextStyle(color: Colors.brightBlack)),
        Text(urls.webUrl!, style: TextStyle(color: Colors.cyan)),
      ]);
    } else if (urls.vmServiceUrl != null && urls.devToolsUrl == null) {
      children.addAll([
        Text('[d] ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightCyan)),
        Text('VM Service ', style: TextStyle(color: Colors.brightBlack)),
        Text(urls.vmServiceUrl!, style: TextStyle(color: Colors.cyan)),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(children: children),
    );
  }
}
