import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tencent_ses/tencent_ses.dart';
import 'package:test/test.dart';

void main() {
  late TencentSesConfig config;

  setUp(() {
    config = const TencentSesConfig(
      secretId: 'test-secret-id',
      secretKey: 'test-secret-key',
      fromEmailAddress: 'QCLOUDTEAM <noreply@example.com>',
      subjectRegister: 'Register subject',
      subjectResetPassword: 'Reset subject',
      templateIdRegister: 2001,
      templateIdResetPassword: 2002,
    );
  });

  group('TencentSesClient', () {
    test('sendTemplateEmail sends request successfully', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'ses.tencentcloudapi.com');
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['FromEmailAddress'], 'QCLOUDTEAM <noreply@example.com>');
        expect(body['Destination'], ['user@example.com']);
        expect(body['Subject'], 'Verification');
        expect(body['Template']['TemplateID'], 1001);
        expect(body['Template']['TemplateData'], '{"code":"123456"}');
        expect(body['TriggerType'], 1);

        return http.Response(
          jsonEncode({
            'Response': {
              'MessageId': 'qcloud-ses-messageid',
              'RequestId': 'test-request-id',
            },
          }),
          200,
        );
      });

      final client = TencentSesClient(config, client: mockClient);
      final response = await client.sendTemplateEmail(
        destination: ['user@example.com'],
        subject: 'Verification',
        templateId: 1001,
        templateData: const {'code': '123456'},
      );

      expect(response.isOk, true);
      expect(response.messageId, 'qcloud-ses-messageid');
      expect(response.requestId, 'test-request-id');
      client.close();
    });

    test('sendTemplateEmail throws config exception for empty destination', () {
      final client = TencentSesClient(config);

      expect(
        () => client.sendTemplateEmail(
          destination: const [],
          subject: 'Verification',
          templateId: 1001,
          templateData: const {'code': '123456'},
        ),
        throwsA(
          isA<TencentSesConfigException>().having(
            (e) => e.message,
            'message',
            'destination cannot be empty',
          ),
        ),
      );

      client.close();
    });

    test('sendTemplateEmail throws send exception on API error', () {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'Error': {
                'Code': 'InvalidTemplateID',
                'Message': 'Template ID is invalid',
              },
              'RequestId': 'test-request-id',
            },
          }),
          200,
        );
      });

      final client = TencentSesClient(config, client: mockClient);
      expect(
        () => client.sendTemplateEmail(
          destination: const ['user@example.com'],
          subject: 'Verification',
          templateId: 1001,
          templateData: const {'code': '123456'},
        ),
        throwsA(
          isA<TencentSesSendException>()
              .having((e) => e.code, 'code', 'InvalidTemplateID')
              .having(
                (e) => e.message,
                'message',
                'SES send failed: Template ID is invalid',
              ),
        ),
      );

      client.close();
    });

    test('sendTemplateEmail throws http exception on 500', () {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = TencentSesClient(config, client: mockClient);
      expect(
        () => client.sendTemplateEmail(
          destination: const ['user@example.com'],
          subject: 'Verification',
          templateId: 1001,
          templateData: const {'code': '123456'},
        ),
        throwsA(
          isA<TencentSesHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                'SES service request failed',
              ),
        ),
      );

      client.close();
    });

    test('sendRegistrationVerificationCode uses configured template', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Template']['TemplateID'], 2001);
        expect(
          body['Template']['TemplateData'],
          '{"code":"654321","requestId":"request-1"}',
        );
        expect(body['Subject'], 'Register subject');
        return http.Response(
          jsonEncode({
            'Response': {'MessageId': 'msg-id', 'RequestId': 'request-id'},
          }),
          200,
        );
      });

      final client = TencentSesClient(config, client: mockClient);
      final response = await client.sendRegistrationVerificationCode(
        email: 'user@example.com',
        verificationCode: '654321',
        requestId: 'request-1',
      );
      expect(response.isOk, true);
      client.close();
    });
  });

  group('SesSendResponse.isOk', () {
    test('isOk returns false when MessageId is missing', () {
      final response = SesSendResponse.fromJson({
        'Response': {'RequestId': 'request-id'},
      });

      expect(response.messageId, isEmpty);
      expect(response.error, isNull);
      expect(response.isOk, isFalse);
    });

    test('isOk returns false when MessageId is empty or whitespace', () {
      for (final messageId in ['', ' ', ' \n\t ']) {
        final response = SesSendResponse.fromJson({
          'Response': {
            'MessageId': messageId,
            'RequestId': 'request-id',
          },
        });
        expect(response.isOk, isFalse,
            reason: 'MessageId=${jsonEncode(messageId)}');
      }
    });

    test('isOk returns true only with a non-blank MessageId and no error', () {
      final response = SesSendResponse.fromJson({
        'Response': {
          'MessageId': ' qcloud-ses-messageid ',
          'RequestId': 'request-id',
        },
      });

      expect(response.isOk, isTrue);
    });
  });
}
