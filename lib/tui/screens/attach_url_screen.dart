import 'package:nocterm/nocterm.dart';
import '../models/tui_attach_target.dart';
import '../components/status_bar.dart';

/// Shown after the user picks a config in the connect screen.
///
/// Prompts for an optional debug URL (`ws://host:port/auth=/ws`).
/// Pressing Enter with an empty field skips straight to auto-scan.
class AttachUrlScreen extends StatefulComponent {
  const AttachUrlScreen({
    required this.target,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  final TuiAttachTarget target;

  /// Called with the typed URL, or `null` when the user pressed Enter on an
  /// empty field (i.e. "auto-scan" mode).
  final void Function(String? url) onSubmit;
  final void Function() onBack;

  @override
  State<AttachUrlScreen> createState() => _AttachUrlScreenState();
}

class _AttachUrlScreenState extends State<AttachUrlScreen> {
  String _input = '';
  bool _loading = false;

  static const _hints = [
    ('enter', 'confirm'),
    ('esc', 'back'),
  ];

  String get _folder => component.target.folderName ?? '';

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: BoxBorder.all(color: Colors.brightBlack)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _Divider(),
          _buildConfigInfo(),
          _Divider(),
          Expanded(child: _loading ? _buildLoading() : _buildInput()),
          _Divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: StatusBar(hints: _hints),
          ),
        ],
      ),
    );
  }

  Component _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '  wsrun — attach',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brightWhite),
      ),
    );
  }

  Component _buildConfigInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Config  ', style: TextStyle(color: Colors.brightBlack)),
            Text(component.target.name, style: TextStyle(color: Colors.brightWhite)),
          ]),
          if (_folder.isNotEmpty)
            Row(children: [
              Text('Folder  ', style: TextStyle(color: Colors.brightBlack)),
              Text(_folder, style: TextStyle(color: Colors.brightBlack)),
            ]),
        ],
      ),
    );
  }

  Component _buildLoading() {
    final msg = _input.isNotEmpty
        ? 'Attaching via debug URL…'
        : 'Scanning for running Flutter process${_folder.isNotEmpty ? " in $_folder" : ""}…';
    return Center(
      child: Text(msg, style: TextStyle(color: Colors.brightBlack)),
    );
  }

  Component _buildInput() {
    final cursor = _input.isEmpty
        ? Text('ws://127.0.0.1:PORT/AUTH=/ws█', style: TextStyle(color: Colors.brightBlack))
        : Text('$_input█', style: TextStyle(color: Colors.brightCyan));

    final hint = _folder.isNotEmpty
        ? 'Leave empty to auto-scan in $_folder'
        : 'Leave empty to auto-scan';

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.enter) {
          final url = _input.trim().isEmpty ? null : _input.trim();
          setState(() => _loading = true);
          component.onSubmit(url);
          return true;
        }
        if (event.logicalKey == LogicalKey.escape) {
          component.onBack();
          return true;
        }
        // 'q' acts as back only when nothing has been typed yet.
        if (event.character?.toLowerCase() == 'q' && _input.isEmpty) {
          component.onBack();
          return true;
        }
        if (event.logicalKey == LogicalKey.backspace) {
          if (_input.isNotEmpty) {
            setState(() => _input = _input.substring(0, _input.length - 1));
          }
          return true;
        }
        final char = event.character;
        if (char != null && char.isNotEmpty) {
          setState(() => _input += char);
          return true;
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 4, top: 2, right: 4),
            child: Text('Debug URL', style: TextStyle(color: Colors.brightBlack)),
          ),
          Container(
            padding: const EdgeInsets.only(left: 4, bottom: 1, right: 4),
            child: cursor,
          ),
          Container(
            padding: const EdgeInsets.only(left: 4, top: 1, right: 4),
            child: Text(hint, style: TextStyle(color: Colors.brightBlack)),
          ),
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
