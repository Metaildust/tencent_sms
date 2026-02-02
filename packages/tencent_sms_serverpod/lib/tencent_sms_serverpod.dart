/// Tencent Cloud SMS Serverpod integration extension.
///
/// Supports reading configuration from Serverpod's passwords.yaml.
///
/// ## Quick Start
///
/// 1. Configure in `config/passwords.yaml`:
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'
///   tencentSmsSecretKey: 'your-secret-key'
///   tencentSmsSdkAppId: '1400000000'
///   tencentSmsSignName: 'YourSignName'
///   tencentSmsRegion: 'ap-guangzhou'
///   tencentSmsVerificationTemplateId: '123456'
/// ```
///
/// 2. Use in code:
///
/// ```dart
/// import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
///
/// final config = TencentSmsConfigServerpod.fromSession(session);
/// final client = TencentSmsClient(config);
/// // Or with Chinese error messages:
/// // final client = TencentSmsClient(config, localizations: const SmsLocalizationsZh());
///
/// await client.sendVerificationCode(
///   phoneNumber: '+8613800138000',
///   verificationCode: '123456',
/// );
/// ```
library tencent_sms_serverpod;

export 'package:tencent_sms/tencent_sms.dart';

export 'src/sms_auth_callback_helper.dart';
export 'src/tencent_sms_config_serverpod.dart';
