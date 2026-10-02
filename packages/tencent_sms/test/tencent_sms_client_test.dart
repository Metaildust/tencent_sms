import 'dart:convert';
import 'dart:io';

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

      test('does not send when every phone number is blank', () async {
        var called = false;
        final mockClient = MockClient((request) async {
          called = true;
          return _okSmsResponse();
        });
        final client = TencentSmsClient(config, client: mockClient);

        await expectLater(
          () => client.sendSms(
            phoneNumbers: ['   ', ''],
            templateId: '123456',
          ),
          throwsA(isA<TencentSmsConfigException>()),
        );
        expect(called, isFalse);
        client.close();
      });

      test('does not send when caller template id is only whitespace',
          () async {
        var called = false;
        final mockClient = MockClient((request) async {
          called = true;
          return _okSmsResponse();
        });
        final client = TencentSmsClient(config, client: mockClient);

        await expectLater(
          () => client.sendSms(
            phoneNumbers: ['+8613800138000'],
            templateId: '   ',
          ),
          throwsA(isA<TencentSmsConfigException>()),
        );
        expect(called, isFalse);

        called = false;
        await expectLater(
          () => client.sendVerificationCode(
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
            templateId: '   ',
          ),
          throwsA(isA<TencentSmsConfigException>()),
        );
        expect(called, isFalse);
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

      test('login send uses the scene template id when a global id also exists',
          () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-login-100,登录验证码\n'
          'scene-register-200,注册验证码\n'
          'scene-reset-300,重置密码验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'scene-login-100');
      });

      test(
          'register send uses the scene template id when a global id also exists',
          () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-login-100,登录验证码\n'
          'scene-register-200,注册验证码\n'
          'scene-reset-300,重置密码验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
          scene: SmsVerificationScene.register,
        );

        expect(sent.templateId, 'scene-register-200');
      });

      test('reset send uses the scene template id when a global id also exists',
          () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-login-100,登录验证码\n'
          'scene-register-200,注册验证码\n'
          'scene-reset-300,重置密码验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
          scene: SmsVerificationScene.resetPassword,
        );

        expect(sent.templateId, 'scene-reset-300');
      });

      test('missing scene template falls back to the global id', () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-register-200,注册验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
            verificationTemplateNameLogin: '登录验证码',
          ),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'global-999');
      });

      test('blank scene template id falls back to the global id', () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          ',登录验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'global-999');
      });

      test(
          'blank global id does not send when there is no scene table',
          () async {
        var called = false;
        final mockClient = MockClient((request) async {
          called = true;
          return _okSmsResponse();
        });
        final client = TencentSmsClient(
          _sceneConfig(verificationTemplateId: '   '),
          client: mockClient,
        );

        await expectLater(
          () => client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.login,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(isA<TencentSmsConfigException>()),
        );
        expect(called, isFalse);
        client.close();
      });

      test(
          'blank global id does not send when the scene table has no id',
          () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          '   ,登录验证码\n',
        );
        var called = false;
        final mockClient = MockClient((request) async {
          called = true;
          return _okSmsResponse();
        });
        final client = TencentSmsClient(
          _sceneConfig(
            verificationTemplateId: '   ',
            templateCsvPath: csvPath,
          ),
          client: mockClient,
        );

        await expectLater(
          () => client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.login,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          ),
          throwsA(isA<TencentSmsConfigException>()),
        );
        expect(called, isFalse);
        client.close();
      });

      test('padded global id is trimmed when there is no scene table',
          () async {
        final sent = await _sendForScene(
          config: _sceneConfig(verificationTemplateId: '  global-999  '),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'global-999');
      });

      test(
          'padded global id is trimmed when the opened table has no scene id',
          () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-register-200,注册验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: '  global-999  ',
            templateCsvPath: csvPath,
          ),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'global-999');
      });

      test('empty scene name falls back to the global id', () async {
        final sent = await _sendForScene(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            verificationTemplateNameLogin: '',
          ),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'global-999');
      });

      test('scene template id is used when the global id is absent', () async {
        final csvPath = await _writeTemplateCsv(
          '模板ID,模板名称\n'
          'scene-login-100,登录验证码\n',
        );
        final sent = await _sendForScene(
          config: _sceneConfig(templateCsvPath: csvPath),
          scene: SmsVerificationScene.login,
        );

        expect(sent.templateId, 'scene-login-100');
      });

      for (final scene in SmsVerificationScene.values) {
        for (final globalId in <String?>[null, '']) {
          final globalLabel = globalId == null ? 'null' : 'empty';
          test(
            '${scene.name} throws and does not send when the scene id is '
            'missing and the global id is $globalLabel',
            () async {
              var called = false;
              final mockClient = MockClient((request) async {
                called = true;
                return _okSmsResponse();
              });
              final client = TencentSmsClient(
                _sceneConfig(verificationTemplateId: globalId),
                client: mockClient,
              );

              await expectLater(
                () => client.sendVerificationCodeForScene(
                  scene: scene,
                  phoneNumber: '+8613800138000',
                  verificationCode: '123456',
                ),
                throwsA(isA<TencentSmsConfigException>()),
              );
              expect(called, isFalse);
              client.close();
            },
          );
        }
      }

      test('missing csv file uses the global template id', () async {
        final csvPath = await _brokenCsvPath(_BrokenCsv.missing);
        final sent = await _captureSceneSend(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
        );

        expect(sent.error, isNull);
        expect(sent.called, isTrue);
        expect(sent.templateId, 'global-999');
      });

      test(
        'same client uses the scene id after a missing csv is replaced',
        () async {
          // 读失败不写缓存，补上合法表后同一客户端要重读。
          final csvPath = await _brokenCsvPath(_BrokenCsv.missing);
          final templateIds = <String?>[];
          final mockClient = MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            templateIds.add(body['TemplateId'] as String?);
            return _okSmsResponse();
          });
          final client = TencentSmsClient(
            _sceneConfig(
              verificationTemplateId: 'global-999',
              templateCsvPath: csvPath,
            ),
            client: mockClient,
          );
          addTearDown(client.close);

          await client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.login,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          );
          expect(templateIds, ['global-999']);

          await File(csvPath).writeAsString(
            '模板ID,模板名称\n'
            'scene-login-100,登录验证码\n',
          );

          await client.sendVerificationCodeForScene(
            scene: SmsVerificationScene.login,
            phoneNumber: '+8613800138000',
            verificationCode: '123456',
          );
          expect(templateIds, ['global-999', 'scene-login-100']);
        },
      );

      test(
          'csv header missing template columns uses the global template id',
          () async {
        final csvPath = await _brokenCsvPath(_BrokenCsv.badHeader);
        final sent = await _captureSceneSend(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
        );

        expect(sent.error, isNull);
        expect(sent.called, isTrue);
        expect(sent.templateId, 'global-999');
      });

      test('unreadable csv bytes use the global template id', () async {
        final csvPath = await _brokenCsvPath(_BrokenCsv.unreadable);
        final sent = await _captureSceneSend(
          config: _sceneConfig(
            verificationTemplateId: 'global-999',
            templateCsvPath: csvPath,
          ),
        );

        expect(sent.error, isNull);
        expect(sent.called, isTrue);
        expect(sent.templateId, 'global-999');
      });

      test('padded global template id is trimmed when the csv cannot be read',
          () async {
        final csvPath = await _brokenCsvPath(_BrokenCsv.missing);
        final sent = await _captureSceneSend(
          config: _sceneConfig(
            verificationTemplateId: '  global-999  ',
            templateCsvPath: csvPath,
          ),
        );

        expect(sent.error, isNull);
        expect(sent.called, isTrue);
        expect(sent.templateId, 'global-999');
      });

      for (final globalId in <String?>[null, '', '   ']) {
        for (final kind in _BrokenCsv.values) {
          test(
            'throws and does not send when csv is ${kind.name} and the '
            'global id is ${_globalIdLabel(globalId)}',
            () async {
              final csvPath = await _brokenCsvPath(kind);
              final sent = await _captureSceneSend(
                config: _sceneConfig(
                  verificationTemplateId: globalId,
                  templateCsvPath: csvPath,
                ),
              );

              expect(sent.error, isA<TencentSmsConfigException>());
              expect(sent.called, isFalse);
              if (kind == _BrokenCsv.unreadable) {
                expect(
                  (sent.error! as TencentSmsConfigException).message,
                  contains('Is a directory'),
                );
              }
            },
          );
        }
      }

      test('empty csv is not treated as a missing file', () async {
        final csvPath = await _writeTemplateCsv('');
        final sent = await _captureSceneSend(
          config: _sceneConfig(templateCsvPath: csvPath),
        );

        expect(sent.called, isFalse);
        expect(sent.error, isA<TencentSmsConfigException>());
        expect(
          (sent.error! as TencentSmsConfigException).message,
          'Verification template ID is not configured for scene: login',
        );
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

    test('isOk returns false when statuses are empty', () {
      final missing = SmsSendResponse.fromJson({
        'Response': {
          'RequestId': 'test-request-id',
        }
      });
      final emptySet = SmsSendResponse.fromJson({
        'Response': {
          'SendStatusSet': [],
          'RequestId': 'test-request-id',
        }
      });
      const constructed = SmsSendResponse(
        statuses: [],
        requestId: 'test-request-id',
      );

      expect(missing.error, isNull);
      expect(missing.statuses, isEmpty);
      expect(missing.isOk, false);
      expect(emptySet.error, isNull);
      expect(emptySet.statuses, isEmpty);
      expect(emptySet.isOk, false);
      expect(constructed.error, isNull);
      expect(constructed.isOk, false);
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

TencentSmsConfig _sceneConfig({
  String? verificationTemplateId,
  String? templateCsvPath,
  String? verificationTemplateNameLogin = '登录验证码',
  String? verificationTemplateNameRegister = '注册验证码',
  String? verificationTemplateNameResetPassword = '重置密码验证码',
}) {
  return TencentSmsConfig(
    secretId: 'test-secret-id',
    secretKey: 'test-secret-key',
    smsSdkAppId: 'test-app-id',
    signName: 'TestSign',
    region: 'ap-guangzhou',
    verificationTemplateId: verificationTemplateId,
    templateCsvPath: templateCsvPath,
    verificationTemplateNameLogin: verificationTemplateNameLogin,
    verificationTemplateNameRegister: verificationTemplateNameRegister,
    verificationTemplateNameResetPassword:
        verificationTemplateNameResetPassword,
  );
}

Future<String> _writeTemplateCsv(String csv) async {
  final dir = await Directory.systemTemp.createTemp('tijing_sms_tpl_');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}/templates.csv');
  await file.writeAsString(csv);
  return file.path;
}

http.Response _okSmsResponse() {
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
}

class _SentSms {
  _SentSms(this.templateId);

  final String? templateId;
}

enum _BrokenCsv { missing, badHeader, unreadable }

String _globalIdLabel(String? globalId) {
  if (globalId == null) return 'null';
  if (globalId.isEmpty) return 'empty';
  return 'blank';
}

/// 坏表三种：文件不存在、表头缺模板列、读字节抛错。
/// 读字节用存在的目录：`File.exists` 对目录为 false，必须真正 `readAsBytes` 才会抛。
Future<String> _brokenCsvPath(_BrokenCsv kind) async {
  switch (kind) {
    case _BrokenCsv.missing:
      final dir = await Directory.systemTemp.createTemp('tijing_sms_tpl_miss_');
      addTearDown(() => dir.delete(recursive: true));
      return '${dir.path}/missing.csv';
    case _BrokenCsv.badHeader:
      return _writeTemplateCsv('模板名称,说明\n登录验证码,x\n');
    case _BrokenCsv.unreadable:
      final dir = await Directory.systemTemp.createTemp('tijing_sms_tpl_dir_');
      addTearDown(() => dir.delete(recursive: true));
      return dir.path;
  }
}

class _SceneSendCapture {
  _SceneSendCapture({
    required this.called,
    required this.templateId,
    required this.error,
  });

  final bool called;
  final String? templateId;
  final Object? error;
}

Future<_SceneSendCapture> _captureSceneSend({
  required TencentSmsConfig config,
  SmsVerificationScene scene = SmsVerificationScene.login,
}) async {
  String? templateId;
  var called = false;
  Object? error;
  final mockClient = MockClient((request) async {
    called = true;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    templateId = body['TemplateId'] as String?;
    return _okSmsResponse();
  });
  final client = TencentSmsClient(config, client: mockClient);
  try {
    await client.sendVerificationCodeForScene(
      scene: scene,
      phoneNumber: '+8613800138000',
      verificationCode: '123456',
    );
  } catch (e) {
    error = e;
  }
  client.close();
  return _SceneSendCapture(
    called: called,
    templateId: templateId,
    error: error,
  );
}

Future<_SentSms> _sendForScene({
  required TencentSmsConfig config,
  required SmsVerificationScene scene,
}) async {
  String? templateId;
  final mockClient = MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    templateId = body['TemplateId'] as String?;
    return _okSmsResponse();
  });
  final client = TencentSmsClient(config, client: mockClient);
  await client.sendVerificationCodeForScene(
    scene: scene,
    phoneNumber: '+8613800138000',
    verificationCode: '123456',
  );
  client.close();
  return _SentSms(templateId);
}
