import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Manages a running `flutter` (or `dart`) child process.
class FlutterProcess {
  FlutterProcess({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });
  final String executable;
  final List<String> arguments;
  final String workingDirectory;

  bool _disposed = false;
  Process? _process;
  final _outputController = StreamController<String>.broadcast();
  final _exitController = StreamController<int>.broadcast();

  /// Broadcast stream of stdout+stderr lines.
  Stream<String> get output => _outputController.stream;

  /// Completes with the exit code when the process ends.
  Stream<int> get onExit => _exitController.stream;

  bool get isRunning => _process != null;

  /// Spawns the process. Throws if already running.
  Future<void> start() async {
    if (_process != null) throw StateError('Process already started');

    _process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );

    // Merge stdout and stderr into the output stream.
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!_disposed) _outputController.add(line);
      },
      onError: (e) {
        if (!_disposed) _outputController.addError(e);
      },
    );

    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!_disposed) _outputController.add(line);
      },
      onError: (e) {
        if (!_disposed) _outputController.addError(e);
      },
    );

    _process!.exitCode.then((code) {
      if (!_disposed) _exitController.add(code);
      _process = null;
    });
  }

  /// Sends [key] followed by a newline to the process stdin (flutter key commands).
  void sendKey(String key) {
    if (_process == null) return;
    _process!.stdin.write('$key\n');
  }

  /// Sends raw bytes to the process stdin.
  void sendBytes(List<int> bytes) {
    if (_process == null) return;
    _process!.stdin.add(bytes);
  }

  /// Gracefully stops the process by sending 'q'.
  Future<void> stop() async {
    if (_process == null) return;
    sendKey('q');
    await Future.any([
      _process!.exitCode,
      Future.delayed(const Duration(seconds: 5)),
    ]);
    kill();
  }

  /// Force-kills the process tree.
  void kill() {
    _process?.kill();
    _process = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    kill();
    await _outputController.close();
    await _exitController.close();
  }
}
