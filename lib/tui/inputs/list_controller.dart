/// Tracks cursor position and scroll offset for a navigable list.
/// Pure Dart — no UI dependency.
class ListController {
  int _cursor = 0;
  int _offset = 0;

  int get cursor => _cursor;
  int get offset => _offset;

  void moveUp() {
    if (_cursor > 0) {
      _cursor--;
      if (_cursor < _offset) _offset = _cursor;
    }
  }

  void moveDown(int itemCount) {
    if (_cursor < itemCount - 1) {
      _cursor++;
    }
  }

  /// Ensures the cursor stays within [0, itemCount).
  void clamp(int itemCount) {
    if (itemCount == 0) {
      _cursor = 0;
      _offset = 0;
      return;
    }
    if (_cursor >= itemCount) _cursor = itemCount - 1;
    if (_cursor < 0) _cursor = 0;
  }

  /// Adjusts the offset so the cursor is within the visible [visibleRows] window.
  void updateOffset(int visibleRows) {
    if (_cursor >= _offset + visibleRows) {
      _offset = _cursor - visibleRows + 1;
    }
    if (_cursor < _offset) _offset = _cursor;
  }

  void reset() {
    _cursor = 0;
    _offset = 0;
  }
}
