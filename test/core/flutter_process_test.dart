import 'dart:async';
import 'package:test/test.dart';
import '../../lib/core/flutter_process.dart';

void main() {
  group('FlutterProcess', () {
    test('throws StateError if started twice', () async {
      final proc = FlutterProcess(
        executable: 'echo',
        arguments: ['hello'],
        workingDirectory: '/tmp',
      );
      await proc.start();
      expect(() => proc.start(), throwsA(isA<StateError>()));
      await proc.dispose();
    });

    test('streams stdout output', () async {
      final proc = FlutterProcess(
        executable: 'echo',
        arguments: ['hello from test'],
        workingDirectory: '/tmp',
      );

      final lines = <String>[];
      final sub = proc.output.listen(lines.add);

      await proc.start();
      await proc.onExit.first;
      await sub.cancel();
      await proc.dispose();

      expect(lines, contains('hello from test'));
    });

    test('onExit emits exit code', () async {
      final proc = FlutterProcess(
        executable: 'true',
        arguments: [],
        workingDirectory: '/tmp',
      );
      await proc.start();
      final code = await proc.onExit.first;
      await proc.dispose();
      expect(code, equals(0));
    });

    test('kill sets isRunning to false', () async {
      final proc = FlutterProcess(
        executable: 'sleep',
        arguments: ['60'],
        workingDirectory: '/tmp',
      );
      await proc.start();
      expect(proc.isRunning, isTrue);
      proc.kill();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(proc.isRunning, isFalse);
      await proc.dispose();
    });
  });
}
