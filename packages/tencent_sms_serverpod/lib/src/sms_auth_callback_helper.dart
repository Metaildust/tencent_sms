import 'package:serverpod/serverpod.dart';
import 'package:tencent_sms/tencent_sms.dart';

/// Helper class for creating SMS send callbacks for serverpod_auth_sms.
///
/// ## Usage Example
///
/// ```dart
/// import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
/// import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';
///
/// void run(List<String> args) async {
///   final pod = Serverpod(args, Protocol(), Endpoints());
///
///   // Create Tencent Cloud SMS client
///   final smsConfig = TencentSmsConfigServerpod.fromServerpod(pod);
///   final smsClient = TencentSmsClient(smsConfig);
///   // Or with Chinese error messages:
///   // final smsClient = TencentSmsClient(smsConfig, localizations: const SmsLocalizationsZh());
///
///   // Create callback helper
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

  /// Creates an SMS authentication callback helper.
  ///
  /// [client] Tencent Cloud SMS client.
  SmsAuthCallbackHelper(this._client);

  /// Sends registration verification code.
  ///
  /// Uses the [SmsVerificationScene.register] scene template.
  Future<void> sendForRegistration(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) async {
    await _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.register,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// Sends login verification code.
  ///
  /// Uses the [SmsVerificationScene.login] scene template.
  Future<void> sendForLogin(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) async {
    await _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.login,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// Sends bind verification code.
  ///
  /// Uses the [SmsVerificationScene.login] scene template (shared with login).
  Future<void> sendForBind(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) async {
    await _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.login,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }

  /// Sends password reset verification code.
  ///
  /// Uses the [SmsVerificationScene.resetPassword] scene template.
  Future<void> sendForResetPassword(
    Session session, {
    required String phone,
    required UuidValue requestId,
    required String verificationCode,
    required Transaction? transaction,
  }) async {
    await _client.sendVerificationCodeForScene(
      scene: SmsVerificationScene.resetPassword,
      phoneNumber: phone,
      verificationCode: verificationCode,
      sessionContext: requestId.toString(),
    );
  }
}
