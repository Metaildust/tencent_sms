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

    test('submits video task payload with URL fileUrl + callback seed',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'vm.tencentcloudapi.com');
        expect(request.headers['X-TC-Action'], 'CreateVideoModerationTask');
        expect(request.headers['X-TC-Version'], '2021-09-22');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['BizType'], 'video-policy');
        expect(body['Type'], 'VIDEO');
        expect(body['CallbackUrl'], 'https://api.example.com/callback');
        expect(body['Seed'], 'seed-123');
        expect(body['User'], isNull);
        expect(body['Device'], isNull);

        final tasks = body['Tasks'] as List<dynamic>;
        expect(tasks, hasLength(1));
        final firstTask = tasks.single as Map<String, dynamic>;
        expect(firstTask['DataId'], 'video-data-1');
        final input = firstTask['Input'] as Map<String, dynamic>;
        expect(input['Type'], 'URL');
        expect(input['Url'], 'https://example.com/a.mp4');
        expect(
          input.containsKey('BucketInfo'),
          isFalse,
          reason: 'COS direct input was removed in 0.2.0; '
              'video moderation must always use Type=URL fileUrl',
        );

        return http.Response(
          jsonEncode({
            'Response': {
              'Results': [
                {
                  'TaskId': 'video-task-1',
                  'DataId': 'video-data-1',
                  'Code': 'OK',
                  'Message': 'Success',
                }
              ],
              'RequestId': 'req-video-1',
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

      final result = await client.createVideoModerationTask(
        const VideoModerationTaskInput(
          fileUrl: 'https://example.com/a.mp4',
          bizType: 'video-policy',
          dataId: 'video-data-1',
          callbackUrl: 'https://api.example.com/callback',
          seed: 'seed-123',
        ),
      );

      expect(result.taskId, 'video-task-1');
      expect(result.requestId, 'req-video-1');
      expect(result.dataId, 'video-data-1');

      client.close();
    });

    test('maps DescribeTaskDetail statuses and labels safely', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'vm.tencentcloudapi.com');
        expect(request.headers['X-TC-Action'], 'DescribeTaskDetail');
        expect(request.headers['X-TC-Version'], '2021-09-22');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['TaskId'], 'video-task-running');

        return http.Response(
          jsonEncode({
            'Response': {
              'TaskId': 'video-task-running',
              'DataId': 'video-data-1',
              'BizType': 'video-policy',
              'Status': 'RUNNING',
              'Suggestion': 'Review',
              'Label': 'Porn',
              'Labels': [
                {
                  'Label': 'Porn',
                  'Suggestion': 'Block',
                  'Score': 99,
                  'SubLabel': 'Sexy',
                }
              ],
              'RequestId': 'req-query-1',
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

      final result = await client.queryModerationTask(
        const ModerationTaskQueryInput(taskId: 'video-task-running'),
      );

      expect(result.taskId, 'video-task-running');
      expect(result.dataId, 'video-data-1');
      expect(result.bizType, 'video-policy');
      expect(result.status, ModerationTaskStatus.running);
      expect(result.isProcessing, isTrue);
      expect(result.decision, ModerationDecision.review);
      expect(result.label, 'Porn');
      expect(result.hits, isNotEmpty);
      expect(result.hits.first.label.name, 'Porn');
      expect(result.hits.first.label.subLabel, 'Sexy');

      client.close();
    });

    test('does not treat Status ERROR with Suggestion Pass as a pass',
        () async {
      // 上游任务失败时仍可能带默认 Suggestion=Pass。总判定不得是通过。
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'TaskId': 'video-task-error',
              'DataId': 'video-data-error',
              'BizType': 'video-policy',
              'Status': 'ERROR',
              'Suggestion': 'Pass',
              'ErrorType': 'URL_ERROR',
              'ErrorDescription':
                  'Server returned 403 Forbidden (access denied)',
              'Labels': [
                {
                  'Label': 'Normal',
                  'Suggestion': 'Pass',
                  'Score': 0,
                }
              ],
              'RequestId': 'req-query-error-pass',
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

      final result = await client.queryModerationTask(
        const ModerationTaskQueryInput(taskId: 'video-task-error'),
      );

      expect(result.status, ModerationTaskStatus.error);
      _expectFailClosedToBlock(result, reason: 'ERROR');

      client.close();
    });

    test('does not treat cancelled or failed status with Pass as a pass',
        () async {
      for (final status in ['CANCELLED', 'CANCELED', 'FAILED', 'FAIL']) {
        final result = await _queryTask({
          'TaskId': 'video-task-case',
          'Status': status,
          'Suggestion': 'Pass',
          'Labels': [
            {'Label': 'Normal', 'Suggestion': 'Pass', 'Score': 0},
          ],
          'RequestId': 'req-query-failed-pass',
        });
        _expectFailClosedToBlock(result, reason: status);
      }
    });

    test('does not treat Pass as a pass when the response carries an error',
        () async {
      const passLabel = {
        'Label': 'Normal',
        'Suggestion': 'Pass',
        'Score': 0,
      };
      final cases = <Map<String, dynamic>>[
        {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorType': 'DECODE_ERROR',
          'Labels': [passLabel],
        },
        {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorDescription': 'download failed',
          'Labels': [passLabel],
        },
        {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'Errors': [
            {'Code': 'URL_ERROR', 'Message': '403 Forbidden'},
          ],
          'Labels': [passLabel],
        },
        {
          'Task': {
            'Status': 'FINISH',
            'Suggestion': 'Pass',
            'TaskId': 'video-task-case',
            'Labels': [passLabel],
          },
          'ErrorType': 'URL_ERROR',
          'ErrorDescription': 'Server returned 403 Forbidden',
        },
      ];
      for (final response in cases) {
        final result = await _queryTask({
          'TaskId': 'video-task-case',
          'RequestId': 'req-query-error-field',
          ...response,
        });
        _expectFailClosedToBlock(result);
      }
    });

    test('keeps Pass when the task finished without an error field', () async {
      final result = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'FINISH',
        'Suggestion': 'Pass',
        'Label': 'Normal',
        'RequestId': 'req-query-finish-pass',
      });
      expect(result.status, ModerationTaskStatus.finish);
      expect(result.decision, ModerationDecision.pass);
    });

    test('keeps Pass while the task is still running', () async {
      final result = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'RUNNING',
        'Suggestion': 'Pass',
        'RequestId': 'req-query-running-pass',
      });
      expect(result.status, ModerationTaskStatus.running);
      expect(result.decision, ModerationDecision.pass);
    });

    test('blocks Pass while still running if a structured task error exists',
        () async {
      final result = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'RUNNING',
        'Suggestion': 'Pass',
        'ErrorType': 'URL_ERROR',
        'RequestId': 'req-query-running-error',
      });
      expect(result.status, ModerationTaskStatus.running);
      expect(result.decision, ModerationDecision.block);
    });

    test('keeps Pass when only body text contains URL_ERROR', () async {
      final result = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'FINISH',
        'Suggestion': 'Pass',
        'AsrText': 'caption mentions URL_ERROR',
        'OcrText': 'frame text URL_ERROR',
        'RequestId': 'req-query-substring',
      });
      expect(result.status, ModerationTaskStatus.finish);
      expect(result.decision, ModerationDecision.pass);
    });

    test(
        'empty suggestion stays review when a detail is block',
        () async {
      for (final suggestion in <Object?>[null, '', '   ']) {
        final response = <String, dynamic>{
          'TaskId': 'video-task-case',
          'Status': 'FINISH',
          'Labels': [
            {'Label': 'Porn', 'Suggestion': 'Block', 'Score': 99},
          ],
          'RequestId': 'req-query-empty-suggestion',
        };
        if (suggestion != null) {
          response['Suggestion'] = suggestion;
        }
        final result = await _queryTask(response);
        expect(result.decision, isNot(ModerationDecision.block));
        expect(result.decision, ModerationDecision.review);
      }
    });

    test('error status still closes the decision to block', () async {
      final result = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'ERROR',
        'Suggestion': 'Pass',
        'RequestId': 'req-query-error-still-block',
      });
      expect(result.decision, ModerationDecision.block);
    });

    test('blocks review when the task failed and keeps block or empty',
        () async {
      final review = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'ERROR',
        'Suggestion': 'Review',
        'Labels': [
          {'Label': 'Porn', 'Suggestion': 'Review', 'Score': 40},
        ],
        'RequestId': 'req-query-error-review',
      });
      expect(review.decision, ModerationDecision.block);
      expect(review.decision, isNot(ModerationDecision.review));
      expect(
        review.hits.map((hit) => hit.decision),
        isNot(contains(ModerationDecision.review)),
      );

      final block = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'ERROR',
        'Suggestion': 'Block',
        'RequestId': 'req-query-error-block',
      });
      expect(block.decision, ModerationDecision.block);

      final missing = await _queryTask({
        'TaskId': 'video-task-case',
        'Status': 'ERROR',
        'RequestId': 'req-query-error-missing',
      });
      // 空建议先落到复审，任务 error 再被失败关闭收成拦截。
      expect(missing.decision, ModerationDecision.block);
      expect(missing.decision == ModerationDecision.pass, isFalse);
    });

    test(
      'blocks Review when a finished task still carries a structured error',
      () async {
        // 完成态建议为复审，但载荷带结构化任务错误时，查询必须拦截。
        // Labels 里原来的 Review 不得留在命中明细里。
        final result = await _queryTask({
          'TaskId': 'video-task-case',
          'Status': 'FINISH',
          'Suggestion': 'Review',
          'ErrorType': 'DECODE_ERROR',
          'Labels': [
            {'Label': 'Porn', 'Suggestion': 'Review', 'Score': 40},
          ],
          'RequestId': 'req-query-finish-review-error',
        });
        expect(result.status, ModerationTaskStatus.finish);
        _expectFailClosedToBlock(result, reason: 'FINISH+Review+ErrorType');
      },
    );

    test('missing text suggestion stays review and Response.Error still throws',
        () async {
      final reviewClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'Label': 'Normal',
              'RequestId': 'req-text-missing-suggestion',
            }
          }),
          200,
        );
      });
      final review = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: reviewClient,
      );
      final text = await review.moderateText(
        const TextModerationInput(content: 'no suggestion'),
      );
      expect(text.decision, ModerationDecision.review);
      expect(text.isPass, isFalse);
      review.close();

      final errorClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'Response': {
              'Error': {
                'Code': 'InvalidParameter',
                'Message': 'bad image',
              },
              'RequestId': 'req-image-error',
            }
          }),
          200,
        );
      });
      final image = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
        client: errorClient,
      );
      expect(
        () => image.moderateImage(
          const ImageModerationInput(fileUrl: 'https://example.com/a.png'),
        ),
        throwsA(isA<TencentContentModerationApiException>()),
      );
      image.close();
    });

    test('maps current task statuses into normalized enum', () {
      expect(
        moderationTaskStatusFromValue('PENDING'),
        ModerationTaskStatus.pending,
      );
      expect(
        moderationTaskStatusFromValue('RUNNING'),
        ModerationTaskStatus.running,
      );
      expect(
        moderationTaskStatusFromValue('FINISH'),
        ModerationTaskStatus.finish,
      );
      expect(
        moderationTaskStatusFromValue('ERROR'),
        ModerationTaskStatus.error,
      );
      expect(
        moderationTaskStatusFromValue('CANCELLED'),
        ModerationTaskStatus.cancelled,
      );
    });

    test('CreateVideoModerationTask surfaces api exception from provider',
        () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Type'], 'VIDEO');
        expect(body['Tasks'], isA<List<dynamic>>());

        return http.Response(
          jsonEncode({
            'Response': {
              'Error': {
                'Code': 'MissingParameter',
                'Message':
                    'The request is missing the required parameter `Tasks`.',
              },
              'RequestId': 'req-missing-tasks',
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
        () => client.createVideoModerationTask(
          const VideoModerationTaskInput(
            fileUrl: 'https://example.com/a.mp4',
            bizType: 'video-policy',
            dataId: 'video-data-1',
          ),
        ),
        throwsA(
          isA<TencentContentModerationApiException>()
              .having((e) => e.errorCode, 'errorCode', 'MissingParameter')
              .having(
                (e) => e.errorMessage,
                'errorMessage',
                contains('Tasks'),
              )
              .having((e) => e.requestId, 'requestId', 'req-missing-tasks'),
        ),
      );

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

    test('blank secretKey throws and does not send', () {
      var called = false;
      expect(
        () => TencentContentModerationClient(
          const TencentCloudApiConfig(
            secretId: 'secret-id',
            secretKey: '   ',
          ),
          client: MockClient((request) async {
            called = true;
            return http.Response('{}', 200);
          }),
        ),
        throwsA(isA<TencentContentModerationConfigException>()),
      );
      expect(called, isFalse);
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

    test('validates video input requires non-empty fileUrl', () async {
      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
      );

      expect(
        () => client.createVideoModerationTask(
          const VideoModerationTaskInput(),
        ),
        throwsA(isA<TencentContentModerationConfigException>()),
      );
      expect(
        () => client.createVideoModerationTask(
          const VideoModerationTaskInput(fileUrl: '   '),
        ),
        throwsA(isA<TencentContentModerationConfigException>()),
      );

      client.close();
    });

    test('validates video input rejects non-http(s) fileUrl', () async {
      // 配套 0.2.0 的「URL 单一入口」约束：caller 必须自己签出 http(s) 预签名 URL，
      // 不能再误传 cos:// / file:// / 纯路径。本测试是从 0.1.0「非法 BucketInfo
      // 应抛」回归保护演化而来的等价覆盖。
      final client = TencentContentModerationClient(
        const TencentCloudApiConfig(
          secretId: 'secret-id',
          secretKey: 'secret-key',
        ),
      );

      const invalidInputs = <VideoModerationTaskInput>[
        VideoModerationTaskInput(fileUrl: 'not-a-url'),
        VideoModerationTaskInput(fileUrl: 'cos://bucket/object.mp4'),
        VideoModerationTaskInput(fileUrl: 'file:///tmp/local.mp4'),
        VideoModerationTaskInput(fileUrl: '/relative/path.mp4'),
        VideoModerationTaskInput(fileUrl: 'ftp://example.com/a.mp4'),
      ];
      for (final input in invalidInputs) {
        expect(
          () => client.createVideoModerationTask(input),
          throwsA(isA<TencentContentModerationConfigException>()),
          reason: 'fileUrl=${input.fileUrl} should be rejected',
        );
      }

      client.close();
    });

    test('video task payload trims surrounding whitespace from fileUrl',
        () async {
      // 与 _ensureValidVideoTaskInput 的 trim 语义对齐：调用方误传带空白的 URL，
      // 既不应该被 client 校验放过，也不应该把未 trim 的字符串泄到 VM payload 上
      // （否则腾讯云 VM 实际拉流时会 404/403）。
      const input = VideoModerationTaskInput(
        fileUrl: '  https://example.com/video.mp4  ',
        bizType: 'scene',
        dataId: 'video-data-1',
      );
      final payload = input.toPayload();
      final tasks = payload['Tasks'] as List<dynamic>;
      final firstTask = tasks.single as Map<String, dynamic>;
      final taskInput = firstTask['Input'] as Map<String, dynamic>;
      expect(taskInput['Url'], equals('https://example.com/video.mp4'));
    });
  });
}

/// 失败关闭必须落到拦截，命中明细里也不能留下通过或复审。
void _expectFailClosedToBlock(
  VideoModerationTaskDetail result, {
  String? reason,
}) {
  expect(result.decision, ModerationDecision.block, reason: reason);
  expect(result.decision, isNot(ModerationDecision.pass), reason: reason);
  expect(result.decision, isNot(ModerationDecision.review), reason: reason);
  expect(result.decision == ModerationDecision.pass, isFalse, reason: reason);
  expect(result.hits, isNotEmpty, reason: reason);
  expect(
    result.hits.map((hit) => hit.decision),
    isNot(contains(ModerationDecision.pass)),
    reason: reason,
  );
  expect(
    result.hits.map((hit) => hit.decision),
    isNot(contains(ModerationDecision.review)),
    reason: reason,
  );
  for (final hit in result.hits) {
    expect(hit.decision, ModerationDecision.block, reason: reason);
  }
}

Future<VideoModerationTaskDetail> _queryTask(
  Map<String, dynamic> response,
) async {
  final mockClient = MockClient((request) async {
    return http.Response(
      jsonEncode({'Response': response}),
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
  try {
    return await client.queryModerationTask(
      const ModerationTaskQueryInput(taskId: 'video-task-case'),
    );
  } finally {
    client.close();
  }
}
