import 'package:serverpod/serverpod.dart';
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

/// Keys for sensitive Tencent Cloud API values in passwords.yaml.
class TencentCloudApiPasswordKeys {
  /// Key for Tencent Cloud Secret ID.
  final String secretId;

  /// Key for Tencent Cloud Secret Key.
  final String secretKey;

  /// Optional key for session token (temporary credentials).
  final String? token;

  const TencentCloudApiPasswordKeys({
    this.secretId = 'tencentSecretId',
    this.secretKey = 'tencentSecretKey',
    this.token,
  });
}

/// Non-sensitive default values.
class TencentCloudApiAppConfig {
  /// Default region for Tencent Cloud API requests.
  final String region;

  const TencentCloudApiAppConfig({this.region = 'ap-guangzhou'});
}

/// Builds [TencentCloudApiConfig] from Serverpod credentials.
class TencentCloudApiConfigServerpod {
  TencentCloudApiConfigServerpod._();

  /// Creates config from [Session].
  static TencentCloudApiConfig fromSession(
    Session session, {
    TencentCloudApiAppConfig appConfig = const TencentCloudApiAppConfig(),
    TencentCloudApiPasswordKeys passwordKeys =
        const TencentCloudApiPasswordKeys(),
  }) {
    return TencentCloudApiConfig(
      secretId: _getPasswordOrThrow(session.serverpod, passwordKeys.secretId),
      secretKey: _getPasswordOrThrow(session.serverpod, passwordKeys.secretKey),
      region: appConfig.region,
      token: _getOptionalPassword(session.serverpod, passwordKeys.token),
    );
  }

  /// Creates config from [Serverpod].
  static TencentCloudApiConfig fromServerpod(
    Serverpod serverpod, {
    TencentCloudApiAppConfig appConfig = const TencentCloudApiAppConfig(),
    TencentCloudApiPasswordKeys passwordKeys =
        const TencentCloudApiPasswordKeys(),
  }) {
    return TencentCloudApiConfig(
      secretId: _getPasswordOrThrow(serverpod, passwordKeys.secretId),
      secretKey: _getPasswordOrThrow(serverpod, passwordKeys.secretKey),
      region: appConfig.region,
      token: _getOptionalPassword(serverpod, passwordKeys.token),
    );
  }

  static String _getPasswordOrThrow(Serverpod serverpod, String key) {
    final value = serverpod.getPassword(key);
    if (value == null || value.isEmpty) {
      throw StateError('$key must be configured in passwords.yaml');
    }
    return value;
  }

  static String? _getOptionalPassword(Serverpod serverpod, String? key) {
    if (key == null || key.isEmpty) return null;
    final value = serverpod.getPassword(key);
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
