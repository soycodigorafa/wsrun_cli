/// A folder entry from the `folders` array in a `.code-workspace` file.
class WorkspaceFolder {
  final String name;
  final String path;

  const WorkspaceFolder({required this.name, required this.path});

  factory WorkspaceFolder.fromJson(Map<String, dynamic> json) {
    return WorkspaceFolder(
      name: json['name'] as String? ?? json['path'] as String,
      path: json['path'] as String,
    );
  }

  @override
  String toString() => 'WorkspaceFolder(name: $name, path: $path)';
}
