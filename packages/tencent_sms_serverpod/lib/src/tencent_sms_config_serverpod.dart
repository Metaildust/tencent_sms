import 'package:serverpod/serverpod.dart';
import 'package:tencent_sms/tencent_sms.dart';

/// 腾讯云短信配置的 Serverpod 扩展
///
/// 支持从 Serverpod 的 passwords.yaml 读取配置。
///
/// ## passwords.yaml 配置项
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'          # 必填
///   tencentSmsSecretKey: 'your-secret-key'        # 必填
///   tencentSmsSdkAppId: '1400000000'              # 必填
///   tencentSmsSignName: '你的签名'                 # 必填
///   tencentSmsRegion: 'ap-guangzhou'              # 可选，默认 ap-guangzhou
///   tencentSmsVerificationTemplateId: '123456'   # 可选，验证码模板 ID
///   tencentSmsTemplateCsvPath: 'config/sms/templates.csv'  # 可选
///   tencentSmsVerificationTemplateNameLogin: '登录验证码'      # 可选
///   tencentSmsVerificationTemplateNameRegister: '注册验证码'   # 可选
///   tencentSmsVerificationTemplateNameResetPassword: '重置密码验证码'  # 可选
///   tencentSmsVerificationTemplateName: '验证码'  # 可选，兼容旧配置
/// ```
class TencentSmsConfigServerpod {
  TencentSmsConfigServerpod._();

  /// 从 Serverpod Session 创建配置
  ///
  /// 从 passwords.yaml 中读取配置项。
  ///
  /// [session] Serverpod Session 对象
  ///
  /// 抛出 [StateError] 如果必填配置项缺失。
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

  /// 从 Serverpod 实例创建配置
  ///
  /// 用于在没有 Session 时（如初始化阶段）读取配置。
  ///
  /// [serverpod] Serverpod 实例
  ///
  /// 抛出 [StateError] 如果必填配置项缺失。
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
