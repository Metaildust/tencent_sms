/// Shared Tencent Cloud API credentials and defaults.
class TencentCloudApiConfig {
  /// Tencent Cloud SecretId.
  final String secretId;

  /// Tencent Cloud SecretKey.
  final String secretKey;

  /// Default region used for requests.
  final String region;

  /// Optional session token for temporary credentials.
  final String? token;

  const TencentCloudApiConfig({
    required this.secretId,
    required this.secretKey,
    this.region = 'ap-guangzhou',
    this.token,
  });

  TencentCloudApiConfig copyWith({
    String? secretId,
    String? secretKey,
    String? region,
    String? token,
  }) {
    return TencentCloudApiConfig(
      secretId: secretId ?? this.secretId,
      secretKey: secretKey ?? this.secretKey,
      region: region ?? this.region,
      token: token ?? this.token,
    );
  }
}
