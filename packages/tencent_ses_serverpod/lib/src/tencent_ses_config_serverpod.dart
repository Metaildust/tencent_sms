import 'package:serverpod/serverpod.dart';
import 'package:tencent_cloud_api_serverpod/tencent_cloud_api_serverpod.dart';
import 'package:tencent_ses/tencent_ses.dart';

/// Keys for sensitive values in `passwords.yaml`.
class TencentSesPasswordKeys {
  /// Key for Tencent Cloud SecretId.
  final String secretId;

  /// Key for Tencent Cloud SecretKey.
  final String secretKey;

  /// Optional key for temporary token.
  final String? token;

  const TencentSesPasswordKeys({
    this.secretId = 'tencentSesSecretId',
    this.secretKey = 'tencentSesSecretKey',
    this.token,
  });

  TencentCloudApiPasswordKeys toApiPasswordKeys() {
    return TencentCloudApiPasswordKeys(
      secretId: secretId,
      secretKey: secretKey,
      token: token,
    );
  }
}

/// Non-sensitive app configuration.
class TencentSesAppConfig {
  /// Region for SES API.
  final String region;

  /// Sender email address.
  final String fromEmailAddress;

  /// Optional reply-to address.
  final String? replyToAddresses;

  /// Subject for registration verification emails.
  final String subjectRegister;

  /// Subject for password reset verification emails.
  final String subjectResetPassword;

  /// Template ID for registration verification.
  final int? templateIdRegister;

  /// Template ID for password reset verification.
  final int? templateIdResetPassword;

  /// Key name for verification code in template data.
  final String templateDataCodeKey;

  /// Optional key name for request ID in template data.
  final String? templateDataRequestIdKey;

  /// Default SES trigger type.
  final int defaultTriggerType;

  const TencentSesAppConfig({
    required this.fromEmailAddress,
    this.region = 'ap-guangzhou',
    this.replyToAddresses,
    this.subjectRegister = '验证码',
    this.subjectResetPassword = '重置密码验证码',
    this.templateIdRegister,
    this.templateIdResetPassword,
    this.templateDataCodeKey = 'code',
    this.templateDataRequestIdKey = 'requestId',
    this.defaultTriggerType = 1,
  });
}

/// Tencent SES config factory for Serverpod.
class TencentSesConfigServerpod {
  TencentSesConfigServerpod._();

  /// Creates config from [Session].
  static TencentSesConfig fromSession(
    Session session, {
    required TencentSesAppConfig appConfig,
    TencentSesPasswordKeys passwordKeys = const TencentSesPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromSession(
      session,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );

    return TencentSesConfig(
      secretId: apiConfig.secretId,
      secretKey: apiConfig.secretKey,
      region: apiConfig.region,
      token: apiConfig.token,
      fromEmailAddress: appConfig.fromEmailAddress,
      replyToAddresses: appConfig.replyToAddresses,
      subjectRegister: appConfig.subjectRegister,
      subjectResetPassword: appConfig.subjectResetPassword,
      templateIdRegister: appConfig.templateIdRegister,
      templateIdResetPassword: appConfig.templateIdResetPassword,
      templateDataCodeKey: appConfig.templateDataCodeKey,
      templateDataRequestIdKey: appConfig.templateDataRequestIdKey,
      defaultTriggerType: appConfig.defaultTriggerType,
    );
  }

  /// Creates config from [Serverpod].
  static TencentSesConfig fromServerpod(
    Serverpod serverpod, {
    required TencentSesAppConfig appConfig,
    TencentSesPasswordKeys passwordKeys = const TencentSesPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromServerpod(
      serverpod,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );

    return TencentSesConfig(
      secretId: apiConfig.secretId,
      secretKey: apiConfig.secretKey,
      region: apiConfig.region,
      token: apiConfig.token,
      fromEmailAddress: appConfig.fromEmailAddress,
      replyToAddresses: appConfig.replyToAddresses,
      subjectRegister: appConfig.subjectRegister,
      subjectResetPassword: appConfig.subjectResetPassword,
      templateIdRegister: appConfig.templateIdRegister,
      templateIdResetPassword: appConfig.templateIdResetPassword,
      templateDataCodeKey: appConfig.templateDataCodeKey,
      templateDataRequestIdKey: appConfig.templateDataRequestIdKey,
      defaultTriggerType: appConfig.defaultTriggerType,
    );
  }
}
