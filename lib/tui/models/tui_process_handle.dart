import 'tui_detected_urls.dart';
import 'tui_log_line.dart';

/// Returned by [AppShell.onRunConfig] to give the shell control over
/// the running process without coupling the TUI layer to [FlutterProcess].
class TuiProcessHandle {
  final Stream<TuiLogLine> logStream;

  /// Emits whenever a new DevTools / VM-service / web URL is detected.
  final Stream<TuiDetectedUrls> urlStream;

  final void Function(String key) sendKey;
  final Future<void> Function() stop;
  final Future<void> Function() dispose;

  /// Opens [url] in the system default browser.
  final Future<void> Function(String url) openUrl;

  const TuiProcessHandle({
    required this.logStream,
    required this.urlStream,
    required this.sendKey,
    required this.stop,
    required this.dispose,
    required this.openUrl,
  });
}
