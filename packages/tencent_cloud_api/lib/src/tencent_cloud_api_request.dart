/// A single Tencent Cloud API 3.0 request definition.
class TencentCloudApiRequest {
  /// API endpoint host, e.g. `tms.tencentcloudapi.com`.
  final String host;

  /// Service name used in TC3 signing scope, e.g. `tms`.
  final String service;

  /// API action, e.g. `TextModeration`.
  final String action;

  /// API version, e.g. `2020-12-29`.
  final String version;

  /// JSON payload body.
  final Map<String, dynamic> payload;

  /// Region override for this request.
  final String? region;

  /// Additional headers merged into the request.
  final Map<String, String> headers;

  const TencentCloudApiRequest({
    required this.host,
    required this.service,
    required this.action,
    required this.version,
    required this.payload,
    this.region,
    this.headers = const {},
  });
}
