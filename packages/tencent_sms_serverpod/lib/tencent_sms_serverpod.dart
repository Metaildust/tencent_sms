/// 腾讯云短信的 Serverpod 集成扩展
///
/// 支持从 Serverpod 的 passwords.yaml 读取配置。
///
/// ## 快速开始
///
/// 1. 在 `config/passwords.yaml` 中配置：
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'
///   tencentSmsSecretKey: 'your-secret-key'
///   tencentSmsSdkAppId: '1400000000'
///   tencentSmsSignName: '你的签名'
///   tencentSmsRegion: 'ap-guangzhou'
///   tencentSmsVerificationTemplateId: '123456'
/// ```
///
/// 2. 在代码中使用：
///
/// ```dart
/// import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
///
/// final config = TencentSmsConfigServerpod.fromSession(session);
/// final client = TencentSmsClient(config);
///
/// await client.sendVerificationCode(
///   phoneNumber: '+8613800138000',
///   verificationCode: '123456',
/// );
/// ```
library tencent_sms_serverpod;

export 'package:tencent_sms/tencent_sms.dart';

export 'src/tencent_sms_config_serverpod.dart';
export 'src/sms_auth_callback_helper.dart';
