import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tencent_sms/tencent_sms.dart';
import 'package:test/test.dart';

void main() {
  late TencentSmsConfig config;

  setUp(() {
    config = TencentSmsConfig(
      secretId: 'test-secret-id',
      secretKey: 'test-secret-key',
      smsSdkAppId: 'test-app-id',
      signName: 'TestSign',
      region: 'ap-guangzhou',
      verificationTemplateId: '123456',
    );
  });

  group('TencentSmsClient', () {
    group('constructor', () {
      test('uses English localizations by default', () {
        final client = TencentSmsClient(config);
        expect(client.localizations, isA<SmsLocalizationsEn>());
        client.close();
      });

      test('accepts custom localizations', () {
        final client = TencentSmsClient(
          config,
          localizations: const SmsLocalizationsZh(),
        );
        expect(client.localizations, isA<SmsLocalizationsZh>());
        client.close();
      });
    });

    group('sendSms', () {
      test('throws exception with English message when phone list is empty',
          () async {
        final client = TencentSmsClient(config);

        expect(
          () => client.sendSms(phoneNumbers: [], templateId: '123'),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              'Phone number list cannot be empty',
            ),
          ),
        );

        client.close();
      });

      test('throws exception with Chinese message when configured', () async {
        final client = TencentSmsClient(
          config,
          localizations: const SmsLocalizationsZh(),
        );

        expect(
          () => client.sendSms(phoneNumbers: [], templateId: '123'),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              '手机号码不能为空',
            ),
          ),
        );

        client.close();
      });

      test('sends SMS successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'sms.tencentcloudapi.com');
          expect(request.method, 'POST');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['PhoneNumberSet'], ['+8613800138000']);
          expect(body['TemplateId'], '123456');
          expect(body['SignName'], 'TestSign');

          return http.Response(
            jsonEncode({
              'Response': {
                'SendStatusSet': [
                  {
                    'SerialNo': '1234',
                    'PhoneNumber': '+8613800138000',
                    'Fee': 1,
                    'Code': 'Ok',
                    'Message': 'send success',
                    'IsoCode': 'CN',
                  }
                ],
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(config, client: mockClient);

        final response = await client.sendSms(
          phoneNumbers: ['+8613800138000'],
          templateId: '123456',
        );

        expect(response.isOk, true);
        expect(response.requestId, 'test-request-id');
        expect(response.statuses.length, 1);
        expect(response.statuses.first.isOk, true);

        client.close();
      });

      test('handles HTTP error with English message', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final client = TencentSmsClient(config, client: mockClient);

        expect(
          () => client.sendSms(
            phoneNumbers: ['+8613800138000'],
            templateId: '123456',
          ),
          throwsA(
            isA<TencentSmsHttpException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having(
                    (e) => e.message, 'message', 'SMS service request failed'),
          ),
        );

        client.close();
      });

      test('handles HTTP error with Chinese message when configured', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final client = TencentSmsClient(
          config,
          client: mockClient,
          localizations: const SmsLocalizationsZh(),
        );

        expect(
          () => client.sendSms(
            phoneNumbers: ['+8613800138000'],
            templateId: '123456',
          ),
          throwsA(
            isA<TencentSmsHttpException>()
                .having((e) => e.message, 'message', '短信服务请求失败'),
          ),
        );

        client.close();
      });
    });

    group('sendVerificationCode', () {
      test('throws exception with English message when template not configured',
          () async {
        final configNoTemplate = TencentSmsConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
          smsSdkAppId: 'test-app-id',
          signName: 'TestSign',
          region: 'ap-guangzhou',
        );

        final client = TencentSmsClient(configNoTemplate);

        expect(
          () => client.sendVerificationCode(
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              'Verification template ID is not configured',
            ),
          ),
        );

        client.close();
      });

      test('throws exception with Chinese message when configured', () async {
        final configNoTemplate = TencentSmsConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
          smsSdkAppId: 'test-app-id',
          signName: 'TestSign',
          region: 'ap-guangzhou',
        );

        final client = TencentSmsClient(
          configNoTemplate,
          localizations: const SmsLocalizationsZh(),
        );

        expect(
          () => client.sendVerificationCode(
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              '未配置验证码模板 ID',
            ),
          ),
        );

        client.close();
      });

      test('throws send exception with localized message on API error',
          () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'Response': {
                'Error': {
                  'Code': 'InvalidParameterValue',
                  'Message': 'Invalid template ID',
                },
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(config, client: mockClient);

        expect(
          () => client.sendVerificationCode(
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsSendException>().having(
              (e) => e.message,
              'message',
              'SMS send failed: Invalid template ID',
            ),
          ),
        );

        client.close();
      });

      test('throws send exception with Chinese message when configured',
          () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'Response': {
                'Error': {
                  'Code': 'InvalidParameterValue',
                  'Message': 'Invalid template ID',
                },
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(
          config,
          client: mockClient,
          localizations: const SmsLocalizationsZh(),
        );

        expect(
          () => client.sendVerificationCode(
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsSendException>().having(
              (e) => e.message,
              'message',
              '短信发送失败: Invalid template ID',
            ),
          ),
        );

        client.close();
      });
    });

    group('sendVerificationCodeForScene', () {
      test('throws exception for unconfigured scene with English message',
          () async {
        final configNoSceneTemplate = TencentSmsConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
          smsSdkAppId: 'test-app-id',
          signName: 'TestSign',
          region: 'ap-guangzhou',
        );

        final client = TencentSmsClient(configNoSceneTemplate);

        expect(
          () => client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.register,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              'Verification template ID is not configured for scene: register',
            ),
          ),
        );

        client.close();
      });

      test('throws exception for unconfigured scene with Chinese message',
          () async {
        final configNoSceneTemplate = TencentSmsConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
          smsSdkAppId: 'test-app-id',
          signName: 'TestSign',
          region: 'ap-guangzhou',
        );

        final client = TencentSmsClient(
          configNoSceneTemplate,
          localizations: const SmsLocalizationsZh(),
        );

        expect(
          () => client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.register,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(
            isA<TencentSmsConfigException>().having(
              (e) => e.message,
              'message',
              '未配置场景 register 的验证码模板 ID',
            ),
          ),
        );

        client.close();
      });
    });

    group('phone number normalization', () {
      test('normalizes Chinese 11-digit numbers to E.164 format', () async {
        String? capturedPhoneNumber;

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final phones = body['PhoneNumberSet'] as List;
          capturedPhoneNumber = phones.first as String;

          return http.Response(
            jsonEncode({
              'Response': {
                'SendStatusSet': [
                  {
                    'SerialNo': '1234',
                    'PhoneNumber': capturedPhoneNumber,
                    'Fee': 1,
                    'Code': 'Ok',
                    'Message': 'send success',
                    'IsoCode': 'CN',
                  }
                ],
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(config, client: mockClient);

        await client.sendSms(
          phoneNumbers: ['13800138000'],
          templateId: '123456',
        );

        expect(capturedPhoneNumber, '+8613800138000');

        client.close();
      });

      test('keeps E.164 format unchanged', () async {
        String? capturedPhoneNumber;

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final phones = body['PhoneNumberSet'] as List;
          capturedPhoneNumber = phones.first as String;

          return http.Response(
            jsonEncode({
              'Response': {
                'SendStatusSet': [
                  {
                    'SerialNo': '1234',
                    'PhoneNumber': capturedPhoneNumber,
                    'Fee': 1,
                    'Code': 'Ok',
                    'Message': 'send success',
                    'IsoCode': 'CN',
                  }
                ],
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(config, client: mockClient);

        await client.sendSms(
          phoneNumbers: ['+8613800138000'],
          templateId: '123456',
        );

        expect(capturedPhoneNumber, '+8613800138000');

        client.close();
      });

      test('converts 00 prefix to + prefix', () async {
        String? capturedPhoneNumber;

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final phones = body['PhoneNumberSet'] as List;
          capturedPhoneNumber = phones.first as String;

          return http.Response(
            jsonEncode({
              'Response': {
                'SendStatusSet': [
                  {
                    'SerialNo': '1234',
                    'PhoneNumber': capturedPhoneNumber,
                    'Fee': 1,
                    'Code': 'Ok',
                    'Message': 'send success',
                    'IsoCode': 'CN',
                  }
                ],
                'RequestId': 'test-request-id',
              }
            }),
            200,
          );
        });

        final client = TencentSmsClient(config, client: mockClient);

        await client.sendSms(
          phoneNumbers: ['008613800138000'],
          templateId: '123456',
        );

        expect(capturedPhoneNumber, '+8613800138000');

        client.close();
      });
    });
  });

  group('SmsSendResponse', () {
    test('isOk returns true when no error and all statuses are Ok', () {
      final response = SmsSendResponse.fromJson({
        'Response': {
          'SendStatusSet': [
            {
              'SerialNo': '1234',
              'PhoneNumber': '+8613800138000',
              'Fee': 1,
              'Code': 'Ok',
              'Message': 'send success',
              'IsoCode': 'CN',
            }
          ],
          'RequestId': 'test-request-id',
        }
      });

      expect(response.isOk, true);
      expect(response.error, isNull);
    });

    test('isOk returns false when error is present', () {
      final response = SmsSendResponse.fromJson({
        'Response': {
          'Error': {
            'Code': 'InvalidParameterValue',
            'Message': 'Invalid template ID',
          },
          'RequestId': 'test-request-id',
        }
      });

      expect(response.isOk, false);
      expect(response.error, isNotNull);
      expect(response.error!.code, 'InvalidParameterValue');
    });

    test('isOk returns false when any status is not Ok', () {
      final response = SmsSendResponse.fromJson({
        'Response': {
          'SendStatusSet': [
            {
              'SerialNo': '1234',
              'PhoneNumber': '+8613800138000',
              'Fee': 0,
              'Code': 'LimitExceeded',
              'Message': 'Rate limit exceeded',
              'IsoCode': 'CN',
            }
          ],
          'RequestId': 'test-request-id',
        }
      });

      expect(response.isOk, false);
      expect(response.statuses.first.isOk, false);
    });
  });

  group('TencentSmsException', () {
    test('toString includes message and code', () {
      const exception = TencentSmsException(
        message: 'Test error',
        code: 'TEST_CODE',
      );

      expect(exception.toString(),
          'TencentSmsException: Test error (code: TEST_CODE)');
    });

    test('toString without code', () {
      const exception = TencentSmsException(message: 'Test error');

      expect(exception.toString(), 'TencentSmsException: Test error');
    });
  });

  group('TencentSmsHttpException', () {
    test('toString includes status code', () {
      const exception = TencentSmsHttpException(
        statusCode: 500,
        message: 'Server error',
      );

      expect(exception.toString(),
          'TencentSmsHttpException: HTTP 500 - Server error');
    });
  });
}
