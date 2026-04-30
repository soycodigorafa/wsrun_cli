/// A rolling log tail that keeps the last [maxLines] lines.
class LogTail {
  final int maxLines;
  final _lines = <String>[];

  LogTail({this.maxLines = 200});

  void addLine(String line) {
    _lines.add(line);
    if (_lines.length > maxLines) _lines.removeAt(0);
  }

  void clear() => _lines.clear();

  /// Returns up to [visibleRows] lines from the tail.
  List<String> render(int visibleRows) {
    if (_lines.isEmpty) return [];
    final start = _lines.length > visibleRows
        ? _lines.length - visibleRows
        : 0;
    return _lines.sublist(start);
  }
}
