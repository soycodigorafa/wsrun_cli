import 'dart:async';
import 'package:nocterm/nocterm.dart';
import '../models/tui_attach_target.dart';
import '../components/config_list.dart';
import '../components/status_bar.dart';
import '../inputs/list_controller.dart';
import '../utils/string_utils.dart';

class ConnectScreen extends StatefulComponent {
  const ConnectScreen({
    required this.onScan,
    required this.onSelect,
    required this.onBack,
    super.key,
  });

  final Future<List<TuiAttachTarget>> Function() onScan;
  final void Function(TuiAttachTarget) onSelect;
  final void Function() onBack;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<TuiAttachTarget>? _targets;
  bool _scanning = true;
  final _list = ListController();

  static const _hints = [
    ('↑↓', 'navigate'),
    ('enter', 'connect'),
    ('q', 'back'),
  ];

  @override
  void initState() {
    super.initState();
    _doScan();
  }

  Future<void> _doScan() async {
    final targets = await component.onScan();
    if (!mounted) return;
    setState(() {
      _targets = targets;
      _scanning = false;
    });
  }

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(color: Colors.brightBlack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '  wsrun — connect',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightWhite),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
            ),
          ),
          Expanded(child: _buildBody()),
          Container(
            decoration: BoxDecoration(
              border: BoxBorder(bottom: BorderSide(color: Colors.brightBlack)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: StatusBar(hints: _hints),
          ),
        ],
      ),
    );
  }

  Component _buildBody() {
    if (_scanning) {
      return Center(
        child: Text(
          'Scanning for running Flutter processes…',
          style: TextStyle(color: Colors.brightBlack),
        ),
      );
    }

    final targets = _targets ?? [];
    if (targets.isEmpty) {
      return Center(
        child: Text(
          'No running Flutter processes found.',
          style: TextStyle(color: Colors.yellow),
        ),
      );
    }

    const visibleRows = 12;
    _list.clamp(targets.length);
    _list.updateOffset(visibleRows);

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(() => _list.moveUp());
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() => _list.moveDown(targets.length));
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          component.onSelect(targets[_list.cursor]);
          return true;
        }
        if (event.character?.toLowerCase() == 'q') {
          component.onBack();
          return true;
        }
        return false;
      },
      child: ConfigList(
        items: targets.map((t) => stripEmojis(t.displayLine)).toList(),
        selectedIndex: _list.cursor,
        scrollOffset: _list.offset,
        visibleRows: visibleRows,
      ),
    );
  }
}
