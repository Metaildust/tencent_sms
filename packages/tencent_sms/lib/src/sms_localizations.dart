/// SMS error message localizations interface.
///
/// Implement this interface to provide custom error messages in your preferred language.
///
/// Example:
/// ```dart
/// class MySmsLocalizations implements SmsLocalizations {
///   @override
///   String get verificationTemplateNotConfigured => 'Template not configured';
///   // ... other messages
/// }
///
/// final client = TencentSmsClient(config, localizations: MySmsLocalizations());
/// ```
abstract class SmsLocalizations {
  /// Error message when verification template ID is not configured.
  String get verificationTemplateNotConfigured;

  /// Error message when scene-specific template is not configured.
  String verificationTemplateNotConfiguredForScene(String sceneName);

  /// Error message when phone number list is empty.
  String get phoneNumbersEmpty;

  /// Error message when SMS sending fails.
  String smsSendFailed(String errorMessage);

  /// Error message when HTTP request fails.
  String get httpRequestFailed;

  /// Error message when template CSV file does not exist.
  String templateCsvNotFound(String path);

  /// Error message when template CSV header is invalid.
  String get templateCsvInvalidHeader;
}

/// Default English localizations for SMS error messages.
class SmsLocalizationsEn implements SmsLocalizations {
  const SmsLocalizationsEn();

  @override
  String get verificationTemplateNotConfigured =>
      'Verification template ID is not configured';

  @override
  String verificationTemplateNotConfiguredForScene(String sceneName) =>
      'Verification template ID is not configured for scene: $sceneName';

  @override
  String get phoneNumbersEmpty => 'Phone number list cannot be empty';

  @override
  String smsSendFailed(String errorMessage) => 'SMS send failed: $errorMessage';

  @override
  String get httpRequestFailed => 'SMS service request failed';

  @override
  String templateCsvNotFound(String path) =>
      'Template CSV file not found: $path';

  @override
  String get templateCsvInvalidHeader =>
      'Template CSV header is invalid. Please ensure the file contains "模板ID" and "模板名称" columns and is UTF-8 encoded';
}

/// Chinese localizations for SMS error messages.
class SmsLocalizationsZh implements SmsLocalizations {
  const SmsLocalizationsZh();

  @override
  String get verificationTemplateNotConfigured => '未配置验证码模板 ID';

  @override
  String verificationTemplateNotConfiguredForScene(String sceneName) =>
      '未配置场景 $sceneName 的验证码模板 ID';

  @override
  String get phoneNumbersEmpty => '手机号码不能为空';

  @override
  String smsSendFailed(String errorMessage) => '短信发送失败: $errorMessage';

  @override
  String get httpRequestFailed => '短信服务请求失败';

  @override
  String templateCsvNotFound(String path) => '验证码模板 CSV 不存在: $path';

  @override
  String get templateCsvInvalidHeader =>
      '验证码模板 CSV 表头不完整，请确保包含"模板ID"和"模板名称"，且文件为 UTF-8 编码';
}
