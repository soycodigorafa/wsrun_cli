/// A UI-only representation of a running Flutter process that can be attached to.
class TuiAttachTarget {
  final int pid;
  final String name;
  final String? device;
  final String? vmServiceUri;

  const TuiAttachTarget({
    required this.pid,
    required this.name,
    this.device,
    this.vmServiceUri,
  });

  String get displayLine {
    final parts = [
      name,
      if (device != null) device!,
      if (vmServiceUri != null) vmServiceUri!,
    ];
    return parts.join('  │  ');
  }
}
