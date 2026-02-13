import 'package:serverpod/serverpod.dart';
import 'package:tencent_cloud_api_serverpod/tencent_cloud_api_serverpod.dart';

/// Keys for sensitive values in `passwords.yaml`.
class TencentContentModerationPasswordKeys {
  /// Key for Tencent Cloud SecretId.
  final String secretId;

  /// Key for Tencent Cloud SecretKey.
  final String secretKey;

  /// Optional key for temporary token.
  final String? token;

  const TencentContentModerationPasswordKeys({
    this.secretId = 'tencentModerationSecretId',
    this.secretKey = 'tencentModerationSecretKey',
    this.token = 'tencentModerationToken',
  });

  TencentCloudApiPasswordKeys toApiPasswordKeys() {
    return TencentCloudApiPasswordKeys(
      secretId: secretId,
      secretKey: secretKey,
      token: token,
    );
  }
}

/// Non-sensitive defaults configured in code.
class TencentContentModerationAppConfig {
  /// Default region for moderation APIs.
  final String region;

  /// Default text moderation strategy (BizType).
  final String? defaultTextBizType;

  /// Default image moderation strategy (BizType).
  final String? defaultImageBizType;

  const TencentContentModerationAppConfig({
    this.region = 'ap-guangzhou',
    this.defaultTextBizType,
    this.defaultImageBizType,
  });
}

/// Combined moderation config used by [ContentModerationService].
class TencentContentModerationServerpodConfig {
  final TencentCloudApiConfig apiConfig;
  final String? defaultTextBizType;
  final String? defaultImageBizType;

  const TencentContentModerationServerpodConfig({
    required this.apiConfig,
    this.defaultTextBizType,
    this.defaultImageBizType,
  });
}

/// Creates moderation config from Serverpod credentials and app defaults.
class TencentContentModerationConfigServerpod {
  TencentContentModerationConfigServerpod._();

  /// Creates config from [Session].
  static TencentContentModerationServerpodConfig fromSession(
    Session session, {
    TencentContentModerationAppConfig appConfig =
        const TencentContentModerationAppConfig(),
    TencentContentModerationPasswordKeys passwordKeys =
        const TencentContentModerationPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromSession(
      session,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );
    return TencentContentModerationServerpodConfig(
      apiConfig: apiConfig,
      defaultTextBizType: _normalize(appConfig.defaultTextBizType),
      defaultImageBizType: _normalize(appConfig.defaultImageBizType),
    );
  }

  /// Creates config from [Serverpod].
  static TencentContentModerationServerpodConfig fromServerpod(
    Serverpod serverpod, {
    TencentContentModerationAppConfig appConfig =
        const TencentContentModerationAppConfig(),
    TencentContentModerationPasswordKeys passwordKeys =
        const TencentContentModerationPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromServerpod(
      serverpod,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );
    return TencentContentModerationServerpodConfig(
      apiConfig: apiConfig,
      defaultTextBizType: _normalize(appConfig.defaultTextBizType),
      defaultImageBizType: _normalize(appConfig.defaultImageBizType),
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
