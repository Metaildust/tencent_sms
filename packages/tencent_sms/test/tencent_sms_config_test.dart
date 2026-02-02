import 'package:tencent_sms/tencent_sms.dart';
import 'package:test/test.dart';

void main() {
  group('TencentSmsConfig', () {
    test('creates config with required parameters', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
      );

      expect(config.secretId, 'test-id');
      expect(config.secretKey, 'test-key');
      expect(config.smsSdkAppId, 'app-id');
      expect(config.signName, 'Sign');
      expect(config.region, 'ap-guangzhou');
    });

    test('verificationTemplateId is optional', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
      );

      expect(config.verificationTemplateId, isNull);
    });

    test('supports scene-specific template names', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
        verificationTemplateNameLogin: 'LoginTemplate',
        verificationTemplateNameRegister: 'RegisterTemplate',
        verificationTemplateNameResetPassword: 'ResetTemplate',
      );

      expect(config.verificationTemplateNameLogin, 'LoginTemplate');
      expect(config.verificationTemplateNameRegister, 'RegisterTemplate');
      expect(config.verificationTemplateNameResetPassword, 'ResetTemplate');
    });

    test('templateNameForScene returns correct template name', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
        verificationTemplateNameLogin: 'LoginTemplate',
        verificationTemplateNameRegister: 'RegisterTemplate',
        verificationTemplateNameResetPassword: 'ResetTemplate',
      );

      expect(
        config.templateNameForScene(SmsVerificationScene.login),
        'LoginTemplate',
      );
      expect(
        config.templateNameForScene(SmsVerificationScene.register),
        'RegisterTemplate',
      );
      expect(
        config.templateNameForScene(SmsVerificationScene.resetPassword),
        'ResetTemplate',
      );
    });

    test(
        'defaultLoginTemplateName uses legacyVerificationTemplateName as fallback',
        () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
        legacyVerificationTemplateName: 'LegacyTemplate',
      );

      expect(config.defaultLoginTemplateName, 'LegacyTemplate');
    });

    test('defaultLoginTemplateName prefers verificationTemplateNameLogin', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
        verificationTemplateNameLogin: 'LoginTemplate',
        legacyVerificationTemplateName: 'LegacyTemplate',
      );

      expect(config.defaultLoginTemplateName, 'LoginTemplate');
    });

    test('templateCsvPath is optional', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
      );

      expect(config.templateCsvPath, isNull);
    });

    test('accepts templateCsvPath for CSV-based template resolution', () {
      final config = TencentSmsConfig(
        secretId: 'test-id',
        secretKey: 'test-key',
        smsSdkAppId: 'app-id',
        signName: 'Sign',
        region: 'ap-guangzhou',
        templateCsvPath: '/path/to/templates.csv',
      );

      expect(config.templateCsvPath, '/path/to/templates.csv');
    });
  });

  group('SmsVerificationScene', () {
    test('has all expected values', () {
      expect(SmsVerificationScene.values, contains(SmsVerificationScene.login));
      expect(
          SmsVerificationScene.values, contains(SmsVerificationScene.register));
      expect(SmsVerificationScene.values,
          contains(SmsVerificationScene.resetPassword));
    });
  });
}
