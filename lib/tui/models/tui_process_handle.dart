import 'tui_log_line.dart';

/// Returned by [AppShell.onRunConfig] to give the shell control over
/// the running process without coupling the TUI layer to [FlutterProcess].
class TuiProcessHandle {
  final Stream<TuiLogLine> logStream;
  final void Function(String key) sendKey;
  final Future<void> Function() stop;
  final Future<void> Function() dispose;

  const TuiProcessHandle({
    required this.logStream,
    required this.sendKey,
    required this.stop,
    required this.dispose,
  });
}
