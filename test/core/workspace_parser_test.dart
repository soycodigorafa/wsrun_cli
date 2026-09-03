import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../../lib/core/workspace_parser.dart';

void main() {
  final fixturePath = p.normalize(p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'sample.code-workspace',
  ));

  group('WorkspaceParser._stripComments', () {
    test('strips line comments', () {
      const input = '{\n  // a comment\n  "key": "value"\n}';
      final stripped = WorkspaceParser.stripCommentsForTest(input);
      expect(stripped, isNot(contains('//')));
      expect(stripped, contains('"key"'));
    });

    test('strips block comments', () {
      const input = '{ /* block */ "key": "value" }';
      final stripped = WorkspaceParser.stripCommentsForTest(input);
      expect(stripped, isNot(contains('/*')));
      expect(stripped, contains('"key"'));
    });

    test('preserves slashes inside strings', () {
      const input = '{ "url": "http://example.com" }';
      final stripped = WorkspaceParser.stripCommentsForTest(input);
      expect(stripped, contains('http://example.com'));
    });

    test('preserves escaped quotes inside strings', () {
      const input = r'{ "msg": "say \"hi\"" }';
      final stripped = WorkspaceParser.stripCommentsForTest(input);
      expect(stripped, contains(r'say \"hi\"'));
    });
  });

  group('WorkspaceParser._stripTrailingCommas', () {
    test('strips trailing comma before closing brace', () {
      const input = '{ "a": 1, }';
      final stripped = WorkspaceParser.stripTrailingCommasForTest(input);
      expect(stripped, equals('{ "a": 1 }'));
    });

    test('strips trailing comma before closing bracket', () {
      const input = '[1, 2, ]';
      final stripped = WorkspaceParser.stripTrailingCommasForTest(input);
      expect(stripped, equals('[1, 2 ]'));
    });

    test('preserves commas inside strings', () {
      const input = r'{ "a": "x, }" }';
      final stripped = WorkspaceParser.stripTrailingCommasForTest(input);
      expect(stripped, equals(input));
    });

    test('leaves non-trailing commas untouched', () {
      const input = '{ "a": 1, "b": 2 }';
      final stripped = WorkspaceParser.stripTrailingCommasForTest(input);
      expect(stripped, equals(input));
    });
  });

  group('WorkspaceParser.parse', () {
    late final workspace = WorkspaceParser.parse(fixturePath);

    test('parses correct number of folders', () {
      expect(workspace.folders.length, equals(3));
    });

    test('parses folder names correctly', () {
      expect(workspace.folders.map((f) => f.name), containsAll([
        '🇺🇸 🟢 App Alpha',
        '🇬🇧 🟢 App Beta',
        'shared',
      ]));
    });

    test('parses correct number of configs', () {
      expect(workspace.configs.length, equals(4));
    });

    test('parses config name including emoji', () {
      expect(workspace.configs.first.name, equals('app_alpha STG'));
    });

    test('parses config program', () {
      expect(workspace.configs.first.program, equals('lib/main.dart'));
    });

    test('parses config args', () {
      expect(workspace.configs.first.args, containsAll(['--flavor', 'dev']));
    });

    test('parses config cwd with workspaceFolder variable', () {
      expect(
        workspace.configs.first.cwd,
        equals(r'${workspaceFolder:🇺🇸 🟢 App Alpha}'),
      );
    });

    test('config with no cwd has null cwd', () {
      final wb = workspace.configs.firstWhere((c) => c.name == 'widgetbook');
      expect(wb.cwd, isNull);
    });
  });
}


