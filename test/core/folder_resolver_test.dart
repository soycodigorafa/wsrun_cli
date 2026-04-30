import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import '../../lib/core/workspace_parser.dart';
import '../../lib/core/folder_resolver.dart';

void main() {
  final fixturePath = p.normalize(p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'sample.code-workspace',
  ));

  late final workspace = WorkspaceParser.parse(fixturePath);
  late FolderResolver resolver;

  setUp(() {
    resolver = FolderResolver(workspace);
  });

  group('FolderResolver.resolve', () {
    test('resolves known workspaceFolder variable to absolute path', () {
      final input = r'${workspaceFolder:🇨🇴 🟢 App Alpha}';
      final result = resolver.resolve(input);
      expect(p.isAbsolute(result), isTrue);
      expect(result, endsWith(p.join('apps', 'app_alpha')));
    });

    test('leaves non-variable strings unchanged', () {
      const input = '/absolute/path/to/something';
      expect(resolver.resolve(input), equals(input));
    });

    test('throws ArgumentError for unknown folder', () {
      expect(
        () => resolver.resolve(r'${workspaceFolder:NONEXISTENT}'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('resolves multiple variables in one string', () {
      final input =
          r'${workspaceFolder:🇨🇴 🟢 App Alpha}/extra:${workspaceFolder:shared}';
      final result = resolver.resolve(input);
      expect(result, contains('app_alpha'));
      expect(result, contains('packages/shared'));
    });
  });

  group('FolderResolver.resolveCwd', () {
    test('null cwd returns workspace directory', () {
      final result = resolver.resolveCwd(null);
      expect(result, equals(p.dirname(workspace.filePath)));
    });

    test('resolves cwd with workspaceFolder variable', () {
      final result = resolver.resolveCwd(
          r'${workspaceFolder:🇦🇷 🟢 App Beta}');
      expect(p.isAbsolute(result), isTrue);
      expect(result, contains('app_beta'));
    });
  });
}
