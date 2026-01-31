/// 腾讯云短信 SDK for Dart/Flutter
///
/// 支持验证码发送、批量发送、CSV模板映射、多场景模板。
///
/// ## 快速开始
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
library tencent_sms;

export 'src/tencent_sms_config.dart';
export 'src/tencent_sms_client.dart';
export 'src/sms_send_response.dart';
export 'src/sms_verification_scene.dart';
export 'src/tencent_sms_exception.dart';
