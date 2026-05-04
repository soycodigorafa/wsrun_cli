import 'dart:io';
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
    required this.onScanTargets,
    super.key,
  });

  final List<TuiConfig> configs;

  /// Called when user picks a config. Returns a [TuiProcessHandle] with the
  /// live log stream and process controls.
  final Future<TuiProcessHandle> Function(TuiConfig config) onRunConfig;

  /// Called when the connect screen needs to scan for running processes.
  final Future<List<TuiAttachTarget>> Function() onScanTargets;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppScreen _screen = _AppScreen.picker;
  TuiConfig? _activeConfig;
  TuiProcessHandle? _activeHandle;

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
          onSendKey: _activeHandle!.sendKey,
          onStop: _activeHandle!.stop,
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

  void _handleTargetSelect(TuiAttachTarget target) {
    // Attach flow wired in integration layer — return to picker for now.
    _handleBackToPicker();
  }

  void _handleBackToPicker() {
    _activeHandle?.dispose();
    setState(() {
      _screen = _AppScreen.picker;
      _activeConfig = null;
      _activeHandle = null;
    });
  }

  void _handleQuit() => exit(0);
}
