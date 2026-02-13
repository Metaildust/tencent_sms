import 'package:serverpod/serverpod.dart';
import 'package:tencent_cloud_api_serverpod/tencent_cloud_api_serverpod.dart';
import 'package:tencent_sms/tencent_sms.dart';

/// Keys for sensitive configuration in passwords.yaml.
class TencentSmsPasswordKeys {
  /// Key for Tencent Cloud Secret ID.
  final String secretId;

  /// Key for Tencent Cloud Secret Key.
  final String secretKey;

  const TencentSmsPasswordKeys({
    this.secretId = 'tencentSmsSecretId',
    this.secretKey = 'tencentSmsSecretKey',
  });

  TencentCloudApiPasswordKeys toApiPasswordKeys() {
    return TencentCloudApiPasswordKeys(
      secretId: secretId,
      secretKey: secretKey,
    );
  }
}

/// Non-sensitive configuration values.
///
/// Pass these directly in code instead of putting in passwords.yaml.
class TencentSmsAppConfig {
  /// SMS SDK App ID from Tencent Cloud console.
  final String smsSdkAppId;

  /// SMS signature name (must be approved in Tencent Cloud console).
  final String signName;

  /// Region for Tencent Cloud SMS service.
  final String region;

  /// Verification template ID (optional, can use template name instead).
  final String? verificationTemplateId;

  /// Path to CSV file containing template mappings.
  final String? templateCsvPath;

  /// Template name for login verification.
  final String? verificationTemplateNameLogin;

  /// Template name for registration verification.
  final String? verificationTemplateNameRegister;

  /// Template name for password reset verification.
  final String? verificationTemplateNameResetPassword;

  const TencentSmsAppConfig({
    required this.smsSdkAppId,
    required this.signName,
    this.region = 'ap-guangzhou',
    this.verificationTemplateId,
    this.templateCsvPath,
    this.verificationTemplateNameLogin,
    this.verificationTemplateNameRegister,
    this.verificationTemplateNameResetPassword,
  });
}

/// Tencent Cloud SMS configuration for Serverpod.
///
/// ## Usage
///
/// ### passwords.yaml (credentials only)
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'
///   tencentSmsSecretKey: 'your-secret-key'
/// ```
///
/// ### Code
///
/// ```dart
/// final config = TencentSmsConfigServerpod.fromServerpod(
///   pod,
///   appConfig: TencentSmsAppConfig(
///     smsSdkAppId: '1400000000',
///     signName: 'YourSignName',
///     templateCsvPath: 'config/sms/templates.csv',
///     verificationTemplateNameLogin: 'Login',
///     verificationTemplateNameRegister: 'Register',
///     verificationTemplateNameResetPassword: 'ResetPassword',
///   ),
/// );
/// ```
class TencentSmsConfigServerpod {
  TencentSmsConfigServerpod._();

  /// Creates configuration from Serverpod Session.
  ///
  /// [session] Serverpod Session object.
  /// [appConfig] Non-sensitive configuration (required).
  /// [passwordKeys] Custom keys for credentials in passwords.yaml.
  static TencentSmsConfig fromSession(
    Session session, {
    required TencentSmsAppConfig appConfig,
    TencentSmsPasswordKeys passwordKeys = const TencentSmsPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromSession(
      session,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );

    return TencentSmsConfig(
      secretId: apiConfig.secretId,
      secretKey: apiConfig.secretKey,
      smsSdkAppId: appConfig.smsSdkAppId,
      signName: appConfig.signName,
      region: apiConfig.region,
      verificationTemplateId: appConfig.verificationTemplateId,
      templateCsvPath: appConfig.templateCsvPath,
      verificationTemplateNameLogin: appConfig.verificationTemplateNameLogin,
      verificationTemplateNameRegister:
          appConfig.verificationTemplateNameRegister,
      verificationTemplateNameResetPassword:
          appConfig.verificationTemplateNameResetPassword,
    );
  }

  /// Creates configuration from Serverpod instance.
  ///
  /// Used when no Session is available (e.g., during initialization).
  ///
  /// [serverpod] Serverpod instance.
  /// [appConfig] Non-sensitive configuration (required).
  /// [passwordKeys] Custom keys for credentials in passwords.yaml.
  static TencentSmsConfig fromServerpod(
    Serverpod serverpod, {
    required TencentSmsAppConfig appConfig,
    TencentSmsPasswordKeys passwordKeys = const TencentSmsPasswordKeys(),
  }) {
    final apiConfig = TencentCloudApiConfigServerpod.fromServerpod(
      serverpod,
      appConfig: TencentCloudApiAppConfig(region: appConfig.region),
      passwordKeys: passwordKeys.toApiPasswordKeys(),
    );

    return TencentSmsConfig(
      secretId: apiConfig.secretId,
      secretKey: apiConfig.secretKey,
      smsSdkAppId: appConfig.smsSdkAppId,
      signName: appConfig.signName,
      region: apiConfig.region,
      verificationTemplateId: appConfig.verificationTemplateId,
      templateCsvPath: appConfig.templateCsvPath,
      verificationTemplateNameLogin: appConfig.verificationTemplateNameLogin,
      verificationTemplateNameRegister:
          appConfig.verificationTemplateNameRegister,
      verificationTemplateNameResetPassword:
          appConfig.verificationTemplateNameResetPassword,
    );
  }
}
