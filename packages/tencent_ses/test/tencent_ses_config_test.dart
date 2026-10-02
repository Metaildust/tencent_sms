import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tencent_ses/tencent_ses.dart';
import 'package:test/test.dart';

void main() {
  group('TencentSesConfig', () {
    test('creates config with required parameters', () {
      final config = TencentSesConfig(
        secretId: 'test-secret-id',
        secretKey: 'test-secret-key',
        fromEmailAddress: 'Sender <sender@example.com>',
      );

      expect(config.secretId, 'test-secret-id');
      expect(config.secretKey, 'test-secret-key');
      expect(config.fromEmailAddress, 'Sender <sender@example.com>');
      expect(config.region, 'ap-guangzhou');
      expect(config.defaultTriggerType, 1);
      expect(config.templateDataCodeKey, 'code');
      expect(config.templateDataRequestIdKey, 'requestId');
      expect(config.subjectRegister, '验证码');
      expect(config.subjectResetPassword, '重置密码验证码');
    });

    test('blank secretKey throws and does not send', () {
      var called = false;
      expect(
        () => TencentSesClient(
          const TencentSesConfig(
            secretId: 'test-secret-id',
            secretKey: '   ',
            fromEmailAddress: 'sender@example.com',
          ),
          client: MockClient((request) async {
            called = true;
            return http.Response('{}', 200);
          }),
        ),
        throwsA(isA<TencentSesConfigException>()),
      );
      expect(called, isFalse);
    });

    test('copyWith keeps old fields and applies updates', () {
      final config = TencentSesConfig(
        secretId: 'id-1',
        secretKey: 'key-1',
        fromEmailAddress: 'sender1@example.com',
        templateIdRegister: 1001,
      );

      final copied = config.copyWith(
        secretKey: 'key-2',
        fromEmailAddress: 'sender2@example.com',
      );

      expect(copied.secretId, 'id-1');
      expect(copied.secretKey, 'key-2');
      expect(copied.fromEmailAddress, 'sender2@example.com');
      expect(copied.templateIdRegister, 1001);
    });
  });
}
