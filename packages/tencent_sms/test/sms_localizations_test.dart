import 'package:tencent_sms/tencent_sms.dart';
import 'package:test/test.dart';

void main() {
  group('SmsLocalizationsEn', () {
    const localizations = SmsLocalizationsEn();

    test('verificationTemplateNotConfigured returns English message', () {
      expect(
        localizations.verificationTemplateNotConfigured,
        'Verification template ID is not configured',
      );
    });

    test('verificationTemplateNotConfiguredForScene returns English message',
        () {
      expect(
        localizations.verificationTemplateNotConfiguredForScene('login'),
        'Verification template ID is not configured for scene: login',
      );
    });

    test('phoneNumbersEmpty returns English message', () {
      expect(
        localizations.phoneNumbersEmpty,
        'Phone number list cannot be empty',
      );
    });

    test('smsSendFailed returns English message with error', () {
      expect(
        localizations.smsSendFailed('Network error'),
        'SMS send failed: Network error',
      );
    });

    test('httpRequestFailed returns English message', () {
      expect(
        localizations.httpRequestFailed,
        'SMS service request failed',
      );
    });

    test('templateCsvNotFound returns English message with path', () {
      expect(
        localizations.templateCsvNotFound('/path/to/file.csv'),
        'Template CSV file not found: /path/to/file.csv',
      );
    });

    test('templateCsvInvalidHeader returns English message', () {
      expect(
        localizations.templateCsvInvalidHeader,
        contains('模板ID'),
      );
    });
  });

  group('SmsLocalizationsZh', () {
    const localizations = SmsLocalizationsZh();

    test('verificationTemplateNotConfigured returns Chinese message', () {
      expect(
        localizations.verificationTemplateNotConfigured,
        '未配置验证码模板 ID',
      );
    });

    test('verificationTemplateNotConfiguredForScene returns Chinese message',
        () {
      expect(
        localizations.verificationTemplateNotConfiguredForScene('login'),
        '未配置场景 login 的验证码模板 ID',
      );
    });

    test('phoneNumbersEmpty returns Chinese message', () {
      expect(
        localizations.phoneNumbersEmpty,
        '手机号码不能为空',
      );
    });

    test('smsSendFailed returns Chinese message with error', () {
      expect(
        localizations.smsSendFailed('网络错误'),
        '短信发送失败: 网络错误',
      );
    });

    test('httpRequestFailed returns Chinese message', () {
      expect(
        localizations.httpRequestFailed,
        '短信服务请求失败',
      );
    });

    test('templateCsvNotFound returns Chinese message with path', () {
      expect(
        localizations.templateCsvNotFound('/path/to/file.csv'),
        '验证码模板 CSV 不存在: /path/to/file.csv',
      );
    });

    test('templateCsvInvalidHeader returns Chinese message', () {
      expect(
        localizations.templateCsvInvalidHeader,
        contains('模板ID'),
      );
    });
  });

  group('Custom SmsLocalizations', () {
    test('can implement custom localizations', () {
      final custom = _CustomLocalizations();

      expect(custom.verificationTemplateNotConfigured, 'Custom: No template');
      expect(
        custom.verificationTemplateNotConfiguredForScene('test'),
        'Custom: No template for test',
      );
    });
  });
}

class _CustomLocalizations implements SmsLocalizations {
  @override
  String get verificationTemplateNotConfigured => 'Custom: No template';

  @override
  String verificationTemplateNotConfiguredForScene(String sceneName) =>
      'Custom: No template for $sceneName';

  @override
  String get phoneNumbersEmpty => 'Custom: Empty phones';

  @override
  String smsSendFailed(String errorMessage) => 'Custom: Failed - $errorMessage';

  @override
  String get httpRequestFailed => 'Custom: HTTP failed';

  @override
  String templateCsvNotFound(String path) => 'Custom: CSV not found at $path';

  @override
  String get templateCsvInvalidHeader => 'Custom: Invalid header';
}
