import 'package:nocterm/nocterm.dart';
import '../models/tui_config.dart';
import '../models/tui_attach_target.dart';
import '../models/tui_process_handle.dart';
import 'picker_screen.dart';
import 'running_screen.dart';
import 'connect_screen.dart';

enum _AppScreen { picker, running, connect }

/// Root component. Owns screen state and routes between picker, running, and connect.
class AppShell extends StatefulComponent {
  const AppShell({
    required this.configs,
    required this.onRunConfig,
    required this.onAttachTarget,
    required this.onScanTargets,
    this.startOnConnect = false,
    super.key,
  });

  final List<TuiConfig> configs;

  /// Called when user picks a config to launch. Returns a [TuiProcessHandle].
  final Future<TuiProcessHandle> Function(TuiConfig config) onRunConfig;

  /// Called when user selects a running process to attach to. Returns a [TuiProcessHandle].
  final Future<TuiProcessHandle> Function(TuiAttachTarget target) onAttachTarget;

  /// Called when the connect screen needs to scan for running processes.
  final Future<List<TuiAttachTarget>> Function() onScanTargets;

  /// When true the shell starts on the connect screen instead of the picker.
  final bool startOnConnect;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late _AppScreen _screen;
  TuiConfig? _activeConfig;
  TuiProcessHandle? _activeHandle;

  @override
  void initState() {
    super.initState();
    _screen = component.startOnConnect ? _AppScreen.connect : _AppScreen.picker;
  }

  @override
  Component build(BuildContext context) {
    return switch (_screen) {
      _AppScreen.picker => PickerScreen(
          configs: component.configs,
          onSelect: _handleSelect,
          onConnect: _handleConnect,
          onQuit: _handleQuit,
        ),
      _AppScreen.running => RunningScreen(
          config: _activeConfig!,
          logStream: _activeHandle!.logStream,
          urlStream: _activeHandle!.urlStream,
          onSendKey: _activeHandle!.sendKey,
          onStop: _activeHandle!.stop,
          onOpenUrl: _activeHandle!.openUrl,
          onBack: _handleBackToPicker,
        ),
      _AppScreen.connect => ConnectScreen(
          onScan: component.onScanTargets,
          onSelect: _handleTargetSelect,
          onBack: _handleBackToPicker,
        ),
    };
  }

  Future<void> _handleSelect(TuiConfig config) async {
    final handle = await component.onRunConfig(config);
    if (!mounted) {
      await handle.dispose();
      return;
    }
    setState(() {
      _activeConfig = config;
      _activeHandle = handle;
      _screen = _AppScreen.running;
    });
  }

  void _handleConnect() {
    setState(() => _screen = _AppScreen.connect);
  }

  void _handleTargetSelect(TuiAttachTarget target) async {
    final handle = await component.onAttachTarget(target);
    if (!mounted) {
      await handle.dispose();
      return;
    }
    setState(() {
      _activeConfig = TuiConfig(name: target.name, type: 'flutter');
      _activeHandle = handle;
      _screen = _AppScreen.running;
    });
  }

  void _handleBackToPicker() {
    _activeHandle?.dispose();
    setState(() {
      _screen = _AppScreen.picker;
      _activeConfig = null;
      _activeHandle = null;
    });
  }

  void _handleQuit() => shutdownApp();
}
