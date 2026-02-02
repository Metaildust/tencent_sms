import 'package:serverpod/serverpod.dart';
import 'package:tencent_sms/tencent_sms.dart';

/// Tencent Cloud SMS configuration extension for Serverpod.
///
/// Supports reading configuration from Serverpod's passwords.yaml.
///
/// ## passwords.yaml Configuration
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'          # Required
///   tencentSmsSecretKey: 'your-secret-key'        # Required
///   tencentSmsSdkAppId: '1400000000'              # Required
///   tencentSmsSignName: 'YourSignName'            # Required
///   tencentSmsRegion: 'ap-guangzhou'              # Optional, default ap-guangzhou
///   tencentSmsVerificationTemplateId: '123456'   # Optional, verification template ID
///   tencentSmsTemplateCsvPath: 'config/sms/templates.csv'  # Optional
///   tencentSmsVerificationTemplateNameLogin: 'LoginTemplate'      # Optional
///   tencentSmsVerificationTemplateNameRegister: 'RegisterTemplate'   # Optional
///   tencentSmsVerificationTemplateNameResetPassword: 'ResetTemplate'  # Optional
///   tencentSmsVerificationTemplateName: 'VerificationTemplate'  # Optional, legacy
/// ```
class TencentSmsConfigServerpod {
  TencentSmsConfigServerpod._();

  /// Creates configuration from Serverpod Session.
  ///
  /// Reads configuration from passwords.yaml.
  ///
  /// [session] Serverpod Session object.
  ///
  /// Throws [StateError] if required configuration is missing.
  static TencentSmsConfig fromSession(Session session) {
    return TencentSmsConfig(
      secretId: _getPasswordOrThrow(session, 'tencentSmsSecretId'),
      secretKey: _getPasswordOrThrow(session, 'tencentSmsSecretKey'),
      smsSdkAppId: _getPasswordOrThrow(session, 'tencentSmsSdkAppId'),
      signName: _getPasswordOrThrow(session, 'tencentSmsSignName'),
      region:
          session.serverpod.getPassword('tencentSmsRegion') ?? 'ap-guangzhou',
      verificationTemplateId: session.serverpod.getPassword(
        'tencentSmsVerificationTemplateId',
      ),
      templateCsvPath: session.serverpod.getPassword(
        'tencentSmsTemplateCsvPath',
      ),
      verificationTemplateNameLogin: session.serverpod.getPassword(
        'tencentSmsVerificationTemplateNameLogin',
      ),
      verificationTemplateNameRegister: session.serverpod.getPassword(
        'tencentSmsVerificationTemplateNameRegister',
      ),
      verificationTemplateNameResetPassword: session.serverpod.getPassword(
        'tencentSmsVerificationTemplateNameResetPassword',
      ),
      legacyVerificationTemplateName: session.serverpod.getPassword(
        'tencentSmsVerificationTemplateName',
      ),
    );
  }

  /// Creates configuration from Serverpod instance.
  ///
  /// Used when no Session is available (e.g., during initialization).
  ///
  /// [serverpod] Serverpod instance.
  ///
  /// Throws [StateError] if required configuration is missing.
  static TencentSmsConfig fromServerpod(Serverpod serverpod) {
    return TencentSmsConfig(
      secretId:
          _getPasswordFromServerpodOrThrow(serverpod, 'tencentSmsSecretId'),
      secretKey:
          _getPasswordFromServerpodOrThrow(serverpod, 'tencentSmsSecretKey'),
      smsSdkAppId:
          _getPasswordFromServerpodOrThrow(serverpod, 'tencentSmsSdkAppId'),
      signName:
          _getPasswordFromServerpodOrThrow(serverpod, 'tencentSmsSignName'),
      region: serverpod.getPassword('tencentSmsRegion') ?? 'ap-guangzhou',
      verificationTemplateId: serverpod.getPassword(
        'tencentSmsVerificationTemplateId',
      ),
      templateCsvPath: serverpod.getPassword(
        'tencentSmsTemplateCsvPath',
      ),
      verificationTemplateNameLogin: serverpod.getPassword(
        'tencentSmsVerificationTemplateNameLogin',
      ),
      verificationTemplateNameRegister: serverpod.getPassword(
        'tencentSmsVerificationTemplateNameRegister',
      ),
      verificationTemplateNameResetPassword: serverpod.getPassword(
        'tencentSmsVerificationTemplateNameResetPassword',
      ),
      legacyVerificationTemplateName: serverpod.getPassword(
        'tencentSmsVerificationTemplateName',
      ),
    );
  }

  static String _getPasswordOrThrow(Session session, String key) {
    final value = session.serverpod.getPassword(key);
    if (value == null || value.isEmpty) {
      throw StateError('$key must be configured in passwords.yaml');
    }
    return value;
  }

  static String _getPasswordFromServerpodOrThrow(
      Serverpod serverpod, String key) {
    final value = serverpod.getPassword(key);
    if (value == null || value.isEmpty) {
      throw StateError('$key must be configured in passwords.yaml');
    }
    return value;
  }
}
