/// Tencent Cloud SMS SDK for Dart/Flutter.
///
/// Supports verification code sending, batch sending, CSV template mapping,
/// and multi-scene templates.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:tencent_sms/tencent_sms.dart';
///
/// final config = TencentSmsConfig(
///   secretId: 'your-secret-id',
///   secretKey: 'your-secret-key',
///   smsSdkAppId: 'your-app-id',
///   signName: 'your-sign-name',
///   region: 'ap-guangzhou',
/// );
///
/// final client = TencentSmsClient(config);
///
/// await client.sendVerificationCode(
///   phoneNumber: '+8613800138000',
///   verificationCode: '123456',
///   templateId: 'your-template-id',
/// );
/// ```
///
/// ## Localization
///
/// By default, error messages are in English. Use `SmsLocalizationsZh` for Chinese:
///
/// ```dart
/// final client = TencentSmsClient(
///   config,
///   localizations: const SmsLocalizationsZh(),
/// );
/// ```
library tencent_sms;

export 'src/sms_localizations.dart';
export 'src/sms_send_response.dart';
export 'src/sms_verification_scene.dart';
export 'src/tencent_sms_client.dart';
export 'src/tencent_sms_config.dart';
export 'src/tencent_sms_exception.dart';
