/// Holds the latest detected debug/service URLs from a running Flutter process.
class TuiDetectedUrls {
  final String? devToolsUrl;
  final String? vmServiceUrl;
  final String? webUrl;

  const TuiDetectedUrls({
    this.devToolsUrl,
    this.vmServiceUrl,
    this.webUrl,
  });

  bool get hasAny => devToolsUrl != null || vmServiceUrl != null || webUrl != null;
}
