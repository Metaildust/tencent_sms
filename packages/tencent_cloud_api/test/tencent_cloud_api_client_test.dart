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
  });
}
