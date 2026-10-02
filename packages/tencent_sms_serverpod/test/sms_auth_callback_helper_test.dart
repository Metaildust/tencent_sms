import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
import 'package:test/test.dart';

class _FakeSession extends Mock implements Session {}

void main() {
  test('sendForBind still sends through the login scene', () async {
    final csvPath = await _writeTemplateCsv(
      '模板ID,模板名称\n'
      'scene-login-100,登录验证码\n'
      'scene-register-200,注册验证码\n',
    );
    final sent = await _sendBind(
      verificationTemplateId: 'global-999',
      templateCsvPath: csvPath,
    );

    expect(sent.templateId, 'scene-login-100');
    expect(sent.templateId, isNot('scene-register-200'));
    expect(sent.templateId, isNot('global-999'));
  });

  test('sendForBind falls back to the global id when login scene id is missing',
      () async {
    final csvPath = await _writeTemplateCsv(
      '模板ID,模板名称\n'
      'scene-register-200,注册验证码\n',
    );
    final sent = await _sendBind(
      verificationTemplateId: 'global-999',
      templateCsvPath: csvPath,
    );

    expect(sent.templateId, 'global-999');
  });
}

Future<String> _writeTemplateCsv(String csv) async {
  final dir = await Directory.systemTemp.createTemp('tijing_sms_bind_');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}/templates.csv');
  await file.writeAsString(csv);
  return file.path;
}

class _SentSms {
  _SentSms(this.templateId);

  final String? templateId;
}

Future<_SentSms> _sendBind({
  required String verificationTemplateId,
  required String templateCsvPath,
}) async {
  String? templateId;
  final mockClient = MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    templateId = body['TemplateId'] as String?;
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
  final client = TencentSmsClient(
    TencentSmsConfig(
      secretId: 'test-secret-id',
      secretKey: 'test-secret-key',
      smsSdkAppId: 'test-app-id',
      signName: 'TestSign',
      region: 'ap-guangzhou',
      verificationTemplateId: verificationTemplateId,
      templateCsvPath: templateCsvPath,
      verificationTemplateNameLogin: '登录验证码',
      verificationTemplateNameRegister: '注册验证码',
      verificationTemplateNameResetPassword: '重置密码验证码',
    ),
    client: mockClient,
  );
  final helper = SmsAuthCallbackHelper(client);
  await helper.sendForBind(
    _FakeSession(),
    phone: '+8613800138000',
    requestId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
    verificationCode: '123456',
    transaction: null,
  );
  client.close();
  return _SentSms(templateId);
}
