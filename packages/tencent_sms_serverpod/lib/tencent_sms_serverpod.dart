/// Tencent Cloud SMS Serverpod integration.
///
/// ## Quick Start
///
/// 1. Put credentials in `config/passwords.yaml`:
///
/// ```yaml
/// shared:
///   tencentSmsSecretId: 'your-secret-id'
///   tencentSmsSecretKey: 'your-secret-key'
/// ```
///
/// 2. Pass non-sensitive config directly:
///
/// ```dart
/// import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
///
/// final config = TencentSmsConfigServerpod.fromServerpod(
///   pod,
///   appConfig: TencentSmsAppConfig(
///     smsSdkAppId: '1400000000',
///     signName: 'YourSignName',
///     templateCsvPath: 'config/sms/templates.csv',
///   ),
/// );
/// final client = TencentSmsClient(config);
/// ```
library tencent_sms_serverpod;

export 'package:tencent_sms/tencent_sms.dart';

export 'src/sms_auth_callback_helper.dart';
export 'src/tencent_sms_config_serverpod.dart';
