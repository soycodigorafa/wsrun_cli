import 'dart:io';
import 'package:dart_console/dart_console.dart';

/// Manages raw terminal mode for stdin.
///
/// In raw mode, keypresses are delivered immediately without line buffering
/// and without echo. Must be restored before the process exits.
class RawTerminal {
  final Console _console = Console();
  bool _rawMode = false;

  bool get isRawMode => _rawMode;

  /// Enables raw mode. No-op if already enabled.
  void enableRawMode() {
    if (_rawMode) return;
    _console.rawMode = true;
    _rawMode = true;
  }

  /// Disables raw mode and restores normal terminal state.
  void disableRawMode() {
    if (!_rawMode) return;
    _console.rawMode = false;
    _rawMode = false;
  }

  /// Clears the entire terminal screen.
  void clearScreen() => _console.clearScreen();

  /// Moves cursor to top-left.
  void resetCursor() => _console.cursorPosition = Coordinate(0, 0);

  /// Hides the terminal cursor.
  void hideCursor() => _console.hideCursor();

  /// Shows the terminal cursor.
  void showCursor() => _console.showCursor();

  int get terminalWidth => _console.windowWidth;
  int get terminalHeight => _console.windowHeight;

  /// Registers a cleanup handler so raw mode is always restored on exit.
  void registerExitHandler() {
    ProcessSignal.sigint.watch().listen((_) {
      disableRawMode();
      showCursor();
      exit(0);
    });
    // SIGTERM — best-effort on platforms that support it.
    try {
      ProcessSignal.sigterm.watch().listen((_) {
        disableRawMode();
        showCursor();
        exit(0);
      });
    } catch (_) {}
  }
}
