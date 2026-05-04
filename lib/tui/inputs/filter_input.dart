import 'package:nocterm/nocterm.dart';

/// An inline text filter input rendered as a single row.
///
/// When [active] is true it captures all char/backspace/escape key events.
/// Reports every change via [onChanged] and exits filtering on Escape or Enter.
class FilterInput extends StatefulComponent {
  const FilterInput({
    required this.value,
    required this.active,
    required this.onChanged,
    required this.onDone,
    super.key,
  });

  final String value;
  final bool active;
  final void Function(String) onChanged;
  final void Function() onDone;

  @override
  State<FilterInput> createState() => _FilterInputState();
}

class _FilterInputState extends State<FilterInput> {
  @override
  Component build(BuildContext context) {
    final display = component.active
        ? '${component.value}█'
        : component.value.isEmpty
            ? 'type to filter...'
            : component.value;

    final textStyle = component.active
        ? TextStyle(color: Colors.brightWhite)
        : component.value.isEmpty
            ? TextStyle(color: Colors.brightBlack)
            : TextStyle(color: Colors.white);

    return Focusable(
      focused: component.active,
      onKeyEvent: (event) {
        if (!component.active) return false;

        if (event.logicalKey == LogicalKey.escape ||
            event.logicalKey == LogicalKey.enter) {
          component.onDone();
          return true;
        }
        if (event.logicalKey == LogicalKey.backspace) {
          if (component.value.isNotEmpty) {
            component.onChanged(component.value.substring(0, component.value.length - 1));
          }
          return true;
        }
        final char = event.character;
        if (char != null && char.isNotEmpty) {
          component.onChanged(component.value + char);
          return true;
        }
        return false;
      },
      child: Row(
        children: [
          Text('  🔍  ', style: TextStyle(color: Colors.brightBlack)),
          Expanded(child: Text(display, style: textStyle)),
        ],
      ),
    );
  }
}
