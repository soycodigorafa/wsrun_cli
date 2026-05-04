import 'package:nocterm/nocterm.dart';

/// Renders a row of keyboard shortcut hints: bold key + dim action label.
class StatusBar extends StatelessComponent {
  const StatusBar({required this.hints, super.key});

  final List<(String key, String action)> hints;

  @override
  Component build(BuildContext context) {
    final children = <Component>[];
    for (var i = 0; i < hints.length; i++) {
      final (key, action) = hints[i];
      if (i > 0) children.add(Text('   '));
      children.add(
        Text(key,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.brightWhite)),
      );
      children.add(Text(' '));
      children.add(
        Text(action, style: TextStyle(color: Colors.brightBlack)),
      );
    }
    return Row(children: children);
  }
}
