/// Utilities for drawing ANSI bordered boxes in the terminal.
class Box {
  // Box-drawing characters (single-line).
  static const _tl = '┌';
  static const _tr = '┐';
  static const _bl = '└';
  static const _br = '┘';
  static const _h = '─';
  static const _v = '│';
  static const _ml = '├';
  static const _mr = '┤';

  /// Renders a full box with an optional [title] in the top border.
  /// Returns a list of lines (without trailing newlines).
  static List<String> render({
    required int width,
    required List<String> lines,
    String title = '',
    String? statusRight,
  }) {
    final result = <String>[];
    final inner = width - 2; // inside border width

    // Top border
    result.add(_topBorder(inner, title, statusRight));

    // Content lines
    for (final line in lines) {
      result.add(_contentLine(line, inner));
    }

    // Bottom border
    result.add('$_bl${_h * inner}$_br');

    return result;
  }

  /// A horizontal divider inside the box.
  static String divider(int width) {
    final inner = width - 2;
    return '$_ml${_h * inner}$_mr';
  }

  static String _topBorder(int inner, String title, String? statusRight) {
    if (title.isEmpty && statusRight == null) {
      return '$_tl${_h * inner}$_tr';
    }

    final titlePart = title.isNotEmpty ? ' $title ' : '';
    final statusPart = statusRight != null ? ' $statusRight ' : '';

    // Visual length (ASCII only for borders — emoji in title are decorative).
    final titleLen = titlePart.length;
    final statusLen = statusPart.length;
    final dashCount = inner - titleLen - statusLen;
    final dashes = dashCount > 0 ? _h * dashCount : '';

    return '$_tl$titlePart$dashes$statusPart$_tr';
  }

  static String _contentLine(String content, int inner) {
    // Trim or pad to fit inner width (simple ASCII truncation).
    final display = _fitWidth(content, inner);
    return '$_v $display${' ' * (inner - 1 - _visibleLength(display))}$_v';
  }

  /// Truncates [s] so its visible (non-ANSI) length fits within [maxWidth - 1]
  /// (accounting for the leading space in content lines).
  static String _fitWidth(String s, int maxWidth) {
    final available = maxWidth - 1;
    if (_visibleLength(s) <= available) return s;
    // Naive truncation (good enough; full grapheme cluster handling is overkill here).
    var len = 0;
    final buf = StringBuffer();
    for (final char in s.characters) {
      if (len + char.length > available - 1) {
        buf.write('…');
        break;
      }
      buf.write(char);
      len += char.length;
    }
    return buf.toString();
  }

  /// Returns the visible character length, ignoring ANSI escape sequences.
  static int _visibleLength(String s) {
    return s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
  }
}

/// Extension so we can iterate over individual characters (runes as strings).
extension on String {
  Iterable<String> get characters sync* {
    final runes = this.runes.toList();
    for (final r in runes) {
      yield String.fromCharCode(r);
    }
  }
}
