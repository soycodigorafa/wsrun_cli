import 'package:dart_console/dart_console.dart';

/// Represents a single key event from stdin.
sealed class KeyEvent {
  const KeyEvent();
}

final class ArrowUp extends KeyEvent {
  const ArrowUp();
}

final class ArrowDown extends KeyEvent {
  const ArrowDown();
}

final class ArrowLeft extends KeyEvent {
  const ArrowLeft();
}

final class ArrowRight extends KeyEvent {
  const ArrowRight();
}

final class EnterKey extends KeyEvent {
  const EnterKey();
}

final class EscapeKey extends KeyEvent {
  const EscapeKey();
}

final class BackspaceKey extends KeyEvent {
  const BackspaceKey();
}

final class CharKey extends KeyEvent {
  final String char;
  const CharKey(this.char);
}

final class UnknownKey extends KeyEvent {
  final List<int> bytes;
  const UnknownKey(this.bytes);
}

/// Reads a single [KeyEvent] from stdin (must be in raw mode).
Future<KeyEvent> readKeyEvent() async {
  final console = Console();
  final key = console.readKey();

  if (key.isControl) {
    return switch (key.controlChar) {
      ControlCharacter.arrowUp => const ArrowUp(),
      ControlCharacter.arrowDown => const ArrowDown(),
      ControlCharacter.arrowLeft => const ArrowLeft(),
      ControlCharacter.arrowRight => const ArrowRight(),
      ControlCharacter.enter => const EnterKey(),
      ControlCharacter.escape => const EscapeKey(),
      ControlCharacter.backspace || ControlCharacter.ctrlH => const BackspaceKey(),
      _ => UnknownKey(const []),
    };
  }

  return CharKey(key.char);
}

/// Stream of [KeyEvent]s from stdin.
Stream<KeyEvent> keyEvents() async* {
  while (true) {
    yield await readKeyEvent();
  }
}
