import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tencent_cloud_api/tencent_cloud_api.dart';
import 'package:test/test.dart';

void main() {
  group('TencentCloudApiClient', () {
    test('sends signed request with required headers', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'sms.tencentcloudapi.com');
        expect(request.headers['Host'], 'sms.tencentcloudapi.com');
        expect(request.headers['X-TC-Action'], 'SendSms');
        expect(request.headers['X-TC-Version'], '2021-01-11');
        expect(request.headers['X-TC-Region'], 'ap-guangzhou');
        expect(request.headers['X-TC-Timestamp'], isNotNull);
        expect(
          request.headers['Authorization'],
          startsWith('TC3-HMAC-SHA256 '),
        );
        expect(
          request.headers['Authorization'],
          contains('SignedHeaders=content-type;host;x-tc-action'),
        );

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['hello'], 'world');

        return http.Response(
          jsonEncode(<String, dynamic>{'Response': <String, dynamic>{}}),
          200,
        );
      });

      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
        ),
        client: mockClient,
      );

      final response = await apiClient.post(
        const TencentCloudApiRequest(
          host: 'sms.tencentcloudapi.com',
          service: 'sms',
          action: 'SendSms',
          version: '2021-01-11',
          payload: <String, dynamic>{
            'hello': 'world',
          },
        ),
      );

      expect(response.containsKey('Response'), true);
      apiClient.close();
    });

    test('throws http exception on non-200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('internal error', 500);
      });

      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
        ),
        client: mockClient,
      );

      expect(
        () => apiClient.post(
          const TencentCloudApiRequest(
            host: 'tms.tencentcloudapi.com',
            service: 'tms',
            action: 'TextModeration',
            version: '2020-12-29',
            payload: <String, dynamic>{'Content': 'dGVzdA=='},
          ),
        ),
        throwsA(
          isA<TencentCloudApiHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );

      apiClient.close();
    });

    test('rejects overriding signed reserved headers', () async {
      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
        ),
      );

      expect(
        () => apiClient.post(
          const TencentCloudApiRequest(
            host: 'tms.tencentcloudapi.com',
            service: 'tms',
            action: 'TextModeration',
            version: '2020-12-29',
            headers: <String, String>{
              'X-TC-Action': 'TamperedAction',
            },
            payload: <String, dynamic>{'Content': 'dGVzdA=='},
          ),
        ),
        throwsA(isA<TencentCloudApiRequestException>()),
      );

      apiClient.close();
    });

    test('json content-type has no charset', () async {
      final mockClient = MockClient((request) async {
        final contentType = request.headers['content-type'];
        expect(contentType, 'application/json');
        expect(contentType, isNot(contains('charset')));
        return http.Response(
          jsonEncode(<String, dynamic>{'Response': <String, dynamic>{}}),
          200,
        );
      });

      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
        ),
        client: mockClient,
      );

      await apiClient.post(
        const TencentCloudApiRequest(
          host: 'sms.tencentcloudapi.com',
          service: 'sms',
          action: 'SendSms',
          version: '2021-01-11',
          payload: <String, dynamic>{'hello': 'world'},
        ),
      );

      apiClient.close();
    });

    test('authorization equals the handwritten literal', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['Authorization'],
          startsWith('TC3-HMAC-SHA256 '),
        );
        expect(request.headers['Authorization'], _handwrittenAuthorization);
        return http.Response(
          jsonEncode(<String, dynamic>{'Response': <String, dynamic>{}}),
          200,
        );
      });

      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'test-secret-key',
        ),
        client: mockClient,
        fixedTimestamp: 1700000000,
      );

      await apiClient.post(
        const TencentCloudApiRequest(
          host: 'sms.tencentcloudapi.com',
          service: 'sms',
          action: 'SendSms',
          version: '2021-01-11',
          payload: <String, dynamic>{'hello': 'world'},
        ),
      );

      apiClient.close();
    });

    test('blank secretKey throws and does not send', () async {
      var called = false;
      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: '   ',
        ),
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        () => apiClient.post(
          const TencentCloudApiRequest(
            host: 'sms.tencentcloudapi.com',
            service: 'sms',
            action: 'SendSms',
            version: '2021-01-11',
            payload: <String, dynamic>{},
          ),
        ),
        throwsA(isA<TencentCloudApiRequestException>()),
      );
      expect(called, isFalse);
      apiClient.close();
    });

    test('wrong secret key does not match the handwritten authorization',
        () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['X-TC-Timestamp'],
          '1700000000',
        );
        expect(
          request.headers['Authorization'],
          isNot(_handwrittenAuthorization),
        );
        return http.Response(
          jsonEncode(<String, dynamic>{'Response': <String, dynamic>{}}),
          200,
        );
      });

      final apiClient = TencentCloudApiClient(
        const TencentCloudApiConfig(
          secretId: 'test-secret-id',
          secretKey: 'wrong-secret-key',
        ),
        client: mockClient,
        fixedTimestamp: 1700000000,
      );

      await apiClient.post(
        const TencentCloudApiRequest(
          host: 'sms.tencentcloudapi.com',
          service: 'sms',
          action: 'SendSms',
          version: '2021-01-11',
          payload: <String, dynamic>{'hello': 'world'},
        ),
      );

      apiClient.close();
    });

    test(
        'handwritten literal differs from wrong key, hmac order, and stringToSign',
        () {
      expect(_handwrittenAuthorization, isNot(_wrongKeyAuthorization));
      expect(_handwrittenAuthorization, isNot(_wrongHmacOrderAuthorization));
      expect(
        _handwrittenAuthorization,
        isNot(_shuffledStringToSignAuthorization),
      );
    });
  });
}

// 冻结时间戳 1700000000（UTC 2023-11-14 22:13:20）、密钥 test-secret-key、
// 载荷 {"hello":"world"}。整段字面量手写在测试里，禁止改成调用被测签名方法。
// 密钥写错、HMAC 不是「日期 → service → tc3_request」、或 stringToSign 四段次序打乱时，
// 相对这条字面量必须失败。不要改生产签名次序去迁就字面量。
const _handwrittenAuthorization = 'TC3-HMAC-SHA256 '
    'Credential=test-secret-id/2023-11-14/sms/tc3_request, '
    'SignedHeaders=content-type;host;x-tc-action, '
    'Signature=4c70ff6892a04361c9e1a53d9178598824c083f4063731990bf25318233de6f8';

const _wrongKeyAuthorization = 'TC3-HMAC-SHA256 '
    'Credential=test-secret-id/2023-11-14/sms/tc3_request, '
    'SignedHeaders=content-type;host;x-tc-action, '
    'Signature=d63e5d147b91a9f1f26716a14e2c5d23a730da02f7cadf8deb4a78fd274f08a2';

const _wrongHmacOrderAuthorization = 'TC3-HMAC-SHA256 '
    'Credential=test-secret-id/2023-11-14/sms/tc3_request, '
    'SignedHeaders=content-type;host;x-tc-action, '
    'Signature=fe54af27a311c1dd8301851800f56011733073a923da03b4ffeea9ce67b41203';

const _shuffledStringToSignAuthorization = 'TC3-HMAC-SHA256 '
    'Credential=test-secret-id/2023-11-14/sms/tc3_request, '
    'SignedHeaders=content-type;host;x-tc-action, '
    'Signature=2acbc7530a9c8ec68d49fe75ed00f2b6fabfbac930d7d3faa53362cd46f06181';
