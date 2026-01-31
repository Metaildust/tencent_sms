import 'package:serverpod/serverpod.dart';
import 'package:tencent_sms/tencent_sms.dart';

/// 为 serverpod_auth_sms 创建短信发送回调的辅助类
///
/// ## 使用示例
///
/// ```dart
/// import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
/// import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';
///
/// void run(List<String> args) async {
///   final pod = Serverpod(args, Protocol(), Endpoints());
///
///   // 创建腾讯云短信客户端
///   final smsConfig = TencentSmsConfigServerpod.fromServerpod(pod);
///   final smsClient = TencentSmsClient(smsConfig);
///
///   // 创建回调辅助类
///   final smsHelper = SmsAuthCallbackHelper(smsClient);
///
///   pod.initializeAuthServices(
///     tokenManagerBuilders: [JwtConfigFromPasswords()],
///     identityProviderBuilders: [
///       SmsIdpConfigFromPasswords(
///         phoneIdStore: phoneIdStore,
///         sendRegistrationVerificationCode: smsHelper.sendForRegistration,
///         sendLoginVerificationCode: smsHelper.sendForLogin,
///         sendBindVerificationCode: smsHelper.sendForBind,
///       ),
///     ],
///   );
///
///   await pod.start();
/// }
/// ```
class SmsAuthCallbackHelper {
  final TencentSmsClient _client;

  /// 创建短信认证回调辅助类
  ///
  /// [client] 腾讯云短信客户端
  SmsAuthCallbackHelper(this._client);

  /// 发送注册验证码
  ///
  /// 使用 [SmsVerificationScene.register] 场景的模板。
  void sendForRegistration(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.register,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// 发送登录验证码
  ///
  /// 使用 [SmsVerificationScene.login] 场景的模板。
  void sendForLogin(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.login,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// 发送绑定验证码
  ///
  /// 使用 [SmsVerificationScene.login] 场景的模板（与登录共用）。
  void sendForBind(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.login,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// 发送重置密码验证码
  ///
  /// 使用 [SmsVerificationScene.resetPassword] 场景的模板。
  void sendForResetPassword(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.resetPassword,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }
}
