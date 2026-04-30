/// Detects Flutter DevTools and VM service URLs from flutter process stdout.
class DevToolsDetector {
  // Matches: "Flutter DevTools: http://127.0.0.1:9100?uri=http%3A%2F%2F..."
  static final _devToolsRegex = RegExp(
    r'Flutter DevTools[^\n]*?(https?://\S+)',
    caseSensitive: false,
  );

  // Matches VM service URI lines, e.g.:
  // "An Observatory debugger and profiler on ... is available at: http://..."
  // "The Dart VM service is listening on http://..."
  static final _vmServiceRegex = RegExp(
    r'(?:Observatory|Dart VM service)[^\n]*?(http://\S+)',
    caseSensitive: false,
  );

  // Matches web server URL: "http://localhost:PORT"
  static final _webUrlRegex = RegExp(
    r'(http://localhost:\d+(?:/\S*)?)',
    caseSensitive: false,
  );

  String? _devToolsUrl;
  String? _vmServiceUrl;
  String? _webUrl;

  String? get devToolsUrl => _devToolsUrl;
  String? get vmServiceUrl => _vmServiceUrl;
  String? get webUrl => _webUrl;

  /// Feed a line of flutter stdout. Returns true if a new URL was detected.
  bool feedLine(String line) {
    bool found = false;
    if (_devToolsUrl == null) {
      final m = _devToolsRegex.firstMatch(line);
      if (m != null) {
        _devToolsUrl = m.group(1);
        found = true;
      }
    }
    if (_vmServiceUrl == null) {
      final m = _vmServiceRegex.firstMatch(line);
      if (m != null) {
        _vmServiceUrl = m.group(1);
        found = true;
      }
    }
    if (_webUrl == null) {
      final m = _webUrlRegex.firstMatch(line);
      if (m != null) {
        _webUrl = m.group(1);
        found = true;
      }
    }
    return found;
  }

  void reset() {
    _devToolsUrl = null;
    _vmServiceUrl = null;
    _webUrl = null;
  }
}
