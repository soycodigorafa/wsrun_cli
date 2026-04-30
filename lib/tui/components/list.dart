/// A scrollable list that renders a window of items with a highlighted cursor.
class ScrollableList {
  final List<String> items;
  int _cursor = 0;
  int _offset = 0;

  ScrollableList(this.items);

  int get cursor => _cursor;
  int get length => items.length;

  void moveUp() {
    if (_cursor > 0) {
      _cursor--;
      if (_cursor < _offset) _offset = _cursor;
    }
  }

  void moveDown() {
    if (_cursor < items.length - 1) {
      _cursor++;
    }
  }

  void reset() {
    _cursor = 0;
    _offset = 0;
  }

  /// Renders [visibleRows] lines. The selected item is prefixed with `❯ `,
  /// others with `  `. ANSI bold is applied to the selected row.
  List<String> render(int visibleRows) {
    // Keep cursor visible.
    if (_cursor >= _offset + visibleRows) {
      _offset = _cursor - visibleRows + 1;
    }

    final result = <String>[];
    for (var i = _offset; i < _offset + visibleRows; i++) {
      if (i >= items.length) {
        result.add('');
        continue;
      }
      final selected = i == _cursor;
      final prefix = selected ? '❯ ' : '  ';
      final text = items[i];
      if (selected) {
        result.add('$prefix\x1B[1m$text\x1B[0m');
      } else {
        result.add('$prefix$text');
      }
    }
    return result;
  }
}
