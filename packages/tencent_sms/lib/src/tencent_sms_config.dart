import 'sms_verification_scene.dart';

/// 腾讯云短信配置
///
/// 对应腾讯云 SendSms API 2021-01-11 版本。
///
/// ## 基本配置
///
/// ```dart
/// final config = TencentSmsConfig(
///   secretId: 'your-secret-id',
///   secretKey: 'your-secret-key',
///   smsSdkAppId: '1400000000',
///   signName: '你的签名',
///   region: 'ap-guangzhou',
/// );
/// ```
///
/// ## 模板配置
///
/// 有两种方式配置验证码模板：
///
/// 1. 直接指定模板 ID：
/// ```dart
/// final config = TencentSmsConfig(
///   // ...基本配置
///   verificationTemplateId: '123456',
/// );
/// ```
///
/// 2. 使用 CSV 文件映射（从腾讯云控制台导出）：
/// ```dart
/// final config = TencentSmsConfig(
///   // ...基本配置
///   templateCsvPath: 'config/sms/templates.csv',
///   verificationTemplateNameLogin: '登录验证码',
///   verificationTemplateNameRegister: '注册验证码',
///   verificationTemplateNameResetPassword: '重置密码验证码',
/// );
/// ```
class TencentSmsConfig {
  /// 腾讯云 SecretId
  final String secretId;

  /// 腾讯云 SecretKey
  final String secretKey;

  /// 短信应用 SDK AppID
  final String smsSdkAppId;

  /// 短信签名内容
  final String signName;

  /// 地域信息（默认 ap-guangzhou）
  final String region;

  /// 验证码模板 ID（优先级最高）
  final String? verificationTemplateId;

  /// 模板 CSV 文件路径（UTF-8 编码，需包含"模板ID"和"模板名称"列）
  final String? templateCsvPath;

  /// 登录场景的模板名称
  final String? verificationTemplateNameLogin;

  /// 注册场景的模板名称
  final String? verificationTemplateNameRegister;

  /// 重置密码场景的模板名称
  final String? verificationTemplateNameResetPassword;

  /// 兼容旧配置的模板名称（优先作为登录模板）
  final String? legacyVerificationTemplateName;

  const TencentSmsConfig({
    required this.secretId,
    required this.secretKey,
    required this.smsSdkAppId,
    required this.signName,
    this.region = 'ap-guangzhou',
    this.verificationTemplateId,
    this.templateCsvPath,
    this.verificationTemplateNameLogin,
    this.verificationTemplateNameRegister,
    this.verificationTemplateNameResetPassword,
    this.legacyVerificationTemplateName,
  });

  /// 获取默认登录模板名称
  String? get defaultLoginTemplateName =>
      verificationTemplateNameLogin ?? legacyVerificationTemplateName;

  /// 根据场景获取模板名称
  String? templateNameForScene(SmsVerificationScene scene) {
    switch (scene) {
      case SmsVerificationScene.login:
        return verificationTemplateNameLogin ?? legacyVerificationTemplateName;
      case SmsVerificationScene.register:
        return verificationTemplateNameRegister;
      case SmsVerificationScene.resetPassword:
        return verificationTemplateNameResetPassword;
    }
  }

  /// 创建配置副本
  TencentSmsConfig copyWith({
    String? secretId,
    String? secretKey,
    String? smsSdkAppId,
    String? signName,
    String? region,
    String? verificationTemplateId,
    String? templateCsvPath,
    String? verificationTemplateNameLogin,
    String? verificationTemplateNameRegister,
    String? verificationTemplateNameResetPassword,
    String? legacyVerificationTemplateName,
  }) {
    return TencentSmsConfig(
      secretId: secretId ?? this.secretId,
      secretKey: secretKey ?? this.secretKey,
      smsSdkAppId: smsSdkAppId ?? this.smsSdkAppId,
      signName: signName ?? this.signName,
      region: region ?? this.region,
      verificationTemplateId:
          verificationTemplateId ?? this.verificationTemplateId,
      templateCsvPath: templateCsvPath ?? this.templateCsvPath,
      verificationTemplateNameLogin:
          verificationTemplateNameLogin ?? this.verificationTemplateNameLogin,
      verificationTemplateNameRegister: verificationTemplateNameRegister ??
          this.verificationTemplateNameRegister,
      verificationTemplateNameResetPassword:
          verificationTemplateNameResetPassword ??
              this.verificationTemplateNameResetPassword,
      legacyVerificationTemplateName:
          legacyVerificationTemplateName ?? this.legacyVerificationTemplateName,
    );
  }
}
