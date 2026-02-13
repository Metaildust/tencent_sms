import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tencent_cloud_api/tencent_cloud_api.dart';
import 'package:tencent_content_moderation/tencent_content_moderation.dart';
import 'package:test/test.dart';

void main() {
  group('TencentContentModerationClient', () {
    test('builds text request with base64 content', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'tms.tencentcloudapi.com');
        expect(request.headers['X-TC-Action'], 'TextModeration');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Content'], 'aGVsbG8gd29ybGQ=');
        expect(body['BizType'], 'text-policy');
        expect(body['DataId'], 'article-title-1');
        expect(body['User'], isA<Map<String, dynamic>>());
        expect(body['Device'], isA<Map<String, dynamic>>());

        return http.Response(
          jsonEncode({
            'Response': {
              'Suggestion': 'Pass',
              'Label': 'Normal',
              'Score': 0,
              'RequestId': 'req-text-pass-1',
            }
          }),
          200,
        );
      });

      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: mockClient,
      );

      final result = await client.moderateText(
        const TextModerationInput(
          content: 'hello world',
          bizType: 'text-policy',
          dataId: 'article-title-1',
          user: ModerationUser(userId: 'u-1001'),
          device: ModerationDevice(platform: 'ios'),
        ),
      );

      expect(result.decision, ModerationDecision.pass);
      expect(result.requestId, 'req-text-pass-1');
      expect(result.label, 'Normal');

      client.close();
    });

    test('maps text detail results and decision safely', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'Suggestion': 'Review',
              'Label': 'Abuse',
              'Score': 88,
              'Keywords': ['foo', 'bar'],
              'DetailResults': [
                {
                  'Suggestion': 'Block',
                  'Label': 'Abuse',
                  'SubLabel': 'Insult',
                  'Score': 99,
                  'Keywords': ['foo'],
                }
              ],
              'RequestId': 'req-text-review-1',
            }
          }),
          200,
        );
      });

      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: mockClient,
      );

      final result = await client.moderateText(
        const TextModerationInput(content: 'review this text'),
      );

      expect(result.decision, ModerationDecision.review);
      expect(result.keywords, containsAll(['foo', 'bar']));
      expect(result.hits.length, 1);
      expect(result.hits.first.decision, ModerationDecision.block);
      expect(result.hits.first.label.subLabel, 'Insult');

      client.close();
    });

    test('maps image response with multiple hit sources', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'ims.tencentcloudapi.com');
        expect(request.headers['X-TC-Action'], 'ImageModeration');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['FileUrl'], 'https://example.com/a.png');
        expect(body.containsKey('FileContent'), false);

        return http.Response(
          jsonEncode({
            'Response': {
              'Suggestion': 'Block',
              'Label': 'Porn',
              'Score': 96,
              'LabelResults': [
                {
                  'Scene': 'Porn',
                  'Label': 'Porn',
                  'SubLabel': 'Sexy',
                  'Suggestion': 'Block',
                  'Score': 99,
                  'Details': [
                    {'Keyword': 'sensitive-word'}
                  ],
                }
              ],
              'ObjectResults': [
                {
                  'Scene': 'Object',
                  'Label': 'Knife',
                  'Suggestion': 'Review',
                  'Score': 62,
                }
              ],
              'RequestId': 'req-image-block-1',
            }
          }),
          200,
        );
      });

      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: mockClient,
      );

      final result = await client.moderateImage(
        const ImageModerationInput(fileUrl: 'https://example.com/a.png'),
      );

      expect(result.decision, ModerationDecision.block);
      expect(result.requestId, 'req-image-block-1');
      expect(result.hits.length, 2);
      expect(result.hits.first.keywords, contains('sensitive-word'));
      expect(result.hits.last.label.name, 'Knife');

      client.close();
    });

    test('maps Response.Error into api exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'Error': {
                'Code': 'InvalidParameterValue.Content',
                'Message': 'content too long',
              },
              'RequestId': 'req-error-1',
            }
          }),
          200,
        );
      });

      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: mockClient,
      );

      expect(
        () => client.moderateText(
          const TextModerationInput(content: 'text'),
        ),
        throwsA(
          isA<TencentContentModerationApiException>()
              .having((e) => e.errorCode, 'errorCode',
                  'InvalidParameterValue.Content')
              .having((e) => e.requestId, 'requestId', 'req-error-1'),
        ),
      );

      client.close();
    });

    test('throws response exception for malformed response shape', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'foo': 'bar'}), 200);
      });

      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: mockClient,
      );

      expect(
        () => client.moderateText(
          const TextModerationInput(content: 'text'),
        ),
        throwsA(isA<TencentContentModerationResponseException>()),
      );

      client.close();
    });

    test('validates image input source constraints', () async {
      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
      );

      expect(
        () => client.moderateImage(const ImageModerationInput()),
        throwsA(isA<TencentContentModerationConfigException>()),
      );
      expect(
        () => client.moderateImage(
          const ImageModerationInput(
            fileUrl: 'https://example.com/a.png',
            fileBase64: 'aGVsbG8=',
          ),
        ),
        throwsA(isA<TencentContentModerationConfigException>()),
      );

      client.close();
    });
  });
}
