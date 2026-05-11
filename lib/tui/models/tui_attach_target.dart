/// A UI-only representation of a workspace config that can be attached to.
class TuiAttachTarget {
  final int pid;
  final String name;
  final String? device;
  final String? vmServiceUri;
  final String? workingDirectory;

  const TuiAttachTarget({
    required this.pid,
    required this.name,
    this.device,
    this.vmServiceUri,
    this.workingDirectory,
  });

  /// Last path segment of [workingDirectory], used for display.
  String? get folderName => workingDirectory?.split('/').last;

  String get displayLine {
    final parts = [
      name,
      if (folderName != null) folderName!,
      if (device != null) device!,
      if (vmServiceUri != null) vmServiceUri!,
    ];
    return parts.join('  │  ');
  }
}
