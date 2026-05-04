import 'package:nocterm/nocterm.dart';

/// Renders a scrollable list of config names with a highlighted cursor row.
class ConfigList extends StatelessComponent {
  const ConfigList({
    required this.items,
    required this.selectedIndex,
    required this.scrollOffset,
    required this.visibleRows,
    super.key,
  });

  final List<String> items;
  final int selectedIndex;
  final int scrollOffset;
  final int visibleRows;

  @override
  Component build(BuildContext context) {
    final rows = <Component>[];
    final end = (scrollOffset + visibleRows).clamp(0, items.length);

    for (var i = scrollOffset; i < end; i++) {
      final selected = i == selectedIndex;
      rows.add(
        Container(
          decoration: selected
              ? BoxDecoration(color: Color.fromRGB(30, 50, 80))
              : null,
          child: Row(
            children: [
              Text(
                selected ? '  ❯ ' : '    ',
                style: TextStyle(color: Colors.brightCyan),
              ),
              Expanded(
                child: Text(
                  items[i],
                  style: selected
                      ? TextStyle(
                          color: Colors.brightWhite,
                          fontWeight: FontWeight.bold,
                        )
                      : TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Pad with empty rows to keep stable height.
    for (var i = end - scrollOffset; i < visibleRows; i++) {
      rows.add(SizedBox(height: 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
