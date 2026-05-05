/// A single launch configuration entry from a `.code-workspace` file.
class LaunchConfig {
  final String name;
  final String? cwd;
  final String? program;
  final List<String> args;
  final String type;
  final String request;

  const LaunchConfig({
    required this.name,
    this.cwd,
    this.program,
    this.args = const [],
    this.type = 'dart',
    this.request = 'launch',
  });

  factory LaunchConfig.fromJson(Map<String, dynamic> json) {
    return LaunchConfig(
      name: json['name'] as String,
      cwd: json['cwd'] as String?,
      program: json['program'] as String?,
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
      type: json['type'] as String? ?? 'dart',
      request: json['request'] as String? ?? 'launch',
    );
  }

  /// Builds the full flutter/dart CLI argument list from this config.
  List<String> toCliArgs() {
    return [
      if (program != null) program!,
      ...args,
    ];
  }

  @override
  String toString() => 'LaunchConfig(name: $name, type: $type)';
}
