/// Holds the latest detected debug/service URLs from a running Flutter process.
class TuiDetectedUrls {
  final String? devToolsUrl;
  final String? vmServiceUrl;
  final String? webUrl;

  /// Set (non-null) only on the single emission where `.zed/debug.json` was
  /// first written. Null on all subsequent URL update events.
  final String? zedAttachPath;

  const TuiDetectedUrls({
    this.devToolsUrl,
    this.vmServiceUrl,
    this.webUrl,
    this.zedAttachPath,
  });

  bool get hasAny => devToolsUrl != null || vmServiceUrl != null || webUrl != null;
}
