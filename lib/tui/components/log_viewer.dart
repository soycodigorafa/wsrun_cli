import 'package:nocterm/nocterm.dart';
import '../models/tui_log_line.dart';

/// Renders a live log tail with auto-scroll to the latest line.
///
/// Uses [AutoScrollController] so it follows new output automatically,
/// but pauses if the user scrolls up to read older lines.
class LogViewer extends StatefulComponent {
  const LogViewer({required this.lines, super.key});

  final List<TuiLogLine> lines;

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final _controller = AutoScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final lines = component.lines;

    if (lines.isEmpty) {
      return Center(
        child: Text(
          'Waiting for output…',
          style: TextStyle(color: Colors.brightBlack),
        ),
      );
    }

    return ListView.builder(
      controller: _controller,
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Text(
          line.text,
          style: TextStyle(color: _colorFor(line.level)),
        );
      },
    );
  }

  Color _colorFor(LogLevel level) => switch (level) {
        LogLevel.warn => Colors.yellow,
        LogLevel.error => Colors.red,
        LogLevel.info => Colors.white,
      };
}
