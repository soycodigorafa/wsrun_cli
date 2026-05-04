import 'package:nocterm/nocterm.dart';
import '../models/tui_config.dart';
import '../components/config_list.dart';
import '../components/status_bar.dart';
import '../inputs/filter_input.dart';
import '../inputs/list_controller.dart';

class PickerScreen extends StatefulComponent {
  const PickerScreen({
    required this.configs,
    required this.onSelect,
    required this.onConnect,
    required this.onQuit,
    super.key,
  });

  final List<TuiConfig> configs;
  final void Function(TuiConfig) onSelect;
  final void Function() onConnect;
  final void Function() onQuit;

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  final _list = ListController();
  String _filter = '';
  bool _filtering = false;

  static const _hints = [
    ('↑↓', 'navigate'),
    ('/', 'filter'),
    ('enter', 'run'),
    ('a', 'attach'),
    ('q', 'quit'),
  ];

  List<TuiConfig> get _filtered {
    if (_filter.isEmpty) return component.configs;
    final lower = _filter.toLowerCase();
    return component.configs.where((c) => c.name.toLowerCase().contains(lower)).toList();
  }

  @override
  Component build(BuildContext context) {
    final filtered = _filtered;
    _list.clamp(filtered.length);

    const visibleRows = 12;
    _list.updateOffset(visibleRows);

    return Focusable(
      focused: !_filtering,
      onKeyEvent: (event) {
        if (_filtering) return false;
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(() => _list.moveUp());
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() => _list.moveDown(filtered.length));
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          if (filtered.isNotEmpty) component.onSelect(filtered[_list.cursor]);
          return true;
        }
        final char = event.character?.toLowerCase();
        if (char == '/') {
          setState(() => _filtering = true);
          return true;
        }
        if (char == 'a') {
          component.onConnect();
          return true;
        }
        if (char == 'q') {
          component.onQuit();
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.brightBlack),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PickerHeader(
              title: 'wsrun',
              right: '${component.configs.length} configs',
            ),
            _Divider(),
            FilterInput(
              value: _filter,
              active: _filtering,
              onChanged: (v) => setState(() {
                _filter = v;
                _list.reset();
              }),
              onDone: () => setState(() => _filtering = false),
            ),
            _Divider(),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No configs match.',
                        style: TextStyle(color: Colors.brightBlack),
                      ),
                    )
                  : ConfigList(
                      items: filtered.map((c) => c.name).toList(),
                      selectedIndex: _list.cursor,
                      scrollOffset: _list.offset,
                      visibleRows: visibleRows,
                    ),
            ),
            _Divider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              child: StatusBar(hints: _hints),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessComponent {
  const _PickerHeader({required this.title, required this.right});
  final String title;
  final String right;

  @override
  Component build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text('  📂  $title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightWhite)),
          Expanded(child: SizedBox()),
          Text(right, style: TextStyle(color: Colors.brightBlack)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessComponent {
  const _Divider();

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
      ),
    );
  }
}
