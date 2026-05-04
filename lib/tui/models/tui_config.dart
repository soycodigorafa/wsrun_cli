/// A UI-only representation of a launch configuration.
/// Contains no dependency on lib/core.
class TuiConfig {
  final String name;
  final String type;

  const TuiConfig({required this.name, required this.type});

  @override
  String toString() => '$type: $name';
}
