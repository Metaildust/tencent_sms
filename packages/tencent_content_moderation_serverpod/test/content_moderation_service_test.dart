import 'package:http/http.dart' as http;
import 'package:tencent_cloud_api/tencent_cloud_api.dart';
import 'package:tencent_content_moderation_serverpod/tencent_content_moderation_serverpod.dart';
import 'package:test/test.dart';

void main() {
  group('ContentModerationService', () {
    test(
        'submitVideoModeration 透传 URL 与默认 BizType + 归一化空白 dataId/callbackUrl/seed',
        () async {
      final client = _FakeTencentContentModerationClient();
      final service = ContentModerationService(
        TencentContentModerationServerpodConfig(
          apiConfig: const TencentCloudApiConfig(
            secretId: 'secret-id',
            secretKey: 'secret-key',
          ),
          defaultVideoBizType: 'video-policy',
        ),
        client: client,
      );

      await service.submitVideoModeration(
        'https://example.com/a.mp4',
        dataId: ' video-data-1 ',
        callbackUrl: ' https://api.example.com/callback ',
        seed: ' seed-123 ',
      );

      final input = client.lastVideoInput;
      expect(input, isNotNull);
      expect(input!.fileUrl, 'https://example.com/a.mp4');
      expect(input.bizType, 'video-policy');
      expect(input.dataId, 'video-data-1');
      expect(input.callbackUrl, 'https://api.example.com/callback');
      expect(input.seed, 'seed-123');
    });

    test('submitVideoModeration 显式传 bizType 时优先于 defaultVideoBizType',
        () async {
      final client = _FakeTencentContentModerationClient();
      final service = ContentModerationService(
        TencentContentModerationServerpodConfig(
          apiConfig: const TencentCloudApiConfig(
            secretId: 'secret-id',
            secretKey: 'secret-key',
          ),
          defaultVideoBizType: 'video-policy',
        ),
        client: client,
      );

      await service.submitVideoModeration(
        'https://example.com/b.mp4',
        bizType: 'override-video-policy',
        dataId: 'video-data-1',
      );

      final input = client.lastVideoInput;
      expect(input, isNotNull);
      expect(input!.bizType, 'override-video-policy');
      expect(input.dataId, 'video-data-1');
      expect(input.fileUrl, 'https://example.com/b.mp4');
    });

    test('任务失败且建议为通过时，查询裁决不保持通过', () async {
      final client = _ErrorPassClient();
      final service = ContentModerationService(
        TencentContentModerationServerpodConfig(
          apiConfig: const TencentCloudApiConfig(
            secretId: 'secret-id',
            secretKey: 'secret-key',
          ),
        ),
        client: client,
      );

      final verdict = await service.queryVideoModeration('video-task-error');

      expect(verdict.status, ModerationTaskStatus.error);
      expect(verdict.decision, ModerationDecision.block);
      expect(verdict.decision, isNot(ModerationDecision.pass));
      expect(verdict.decision == ModerationDecision.pass, isFalse);
      expect(verdict.hits, isNotEmpty);
      expect(
        verdict.hits.map((hit) => hit.decision),
        isNot(contains(ModerationDecision.pass)),
      );
      expect(verdict.hits.single.decision, ModerationDecision.block);
    });

    test('完成但原始响应带错误字段时，裁决不保持通过', () {
      final verdict = VideoModerationTaskVerdict.fromVideoTaskDetail(
        const VideoModerationTaskDetail(
          taskId: 'video-task-url',
          status: ModerationTaskStatus.finish,
          requestId: 'req-url',
          decision: ModerationDecision.pass,
          rawResponse: {
            'Status': 'FINISH',
            'Suggestion': 'Pass',
            'ErrorDescription': 'URL_ERROR while fetching media',
          },
          hits: [
            ModerationHit(
              decision: ModerationDecision.pass,
              label: ModerationLabel(name: 'Normal'),
            ),
          ],
        ),
      );

      expect(verdict.decision, ModerationDecision.block);
      expect(verdict.decision, isNot(ModerationDecision.pass));
      expect(verdict.decision == ModerationDecision.pass, isFalse);
      expect(verdict.hits, isNotEmpty);
      expect(
        verdict.hits.map((hit) => hit.decision),
        isNot(contains(ModerationDecision.pass)),
      );
      expect(verdict.hits.single.decision, ModerationDecision.block);
    });

    test('完成且没有错误字段时，裁决仍保留通过', () {
      final verdict = VideoModerationTaskVerdict.fromVideoTaskDetail(
        const VideoModerationTaskDetail(
          taskId: 'video-task-ok',
          status: ModerationTaskStatus.finish,
          requestId: 'req-ok',
          decision: ModerationDecision.pass,
          rawResponse: {
            'Status': 'FINISH',
            'Suggestion': 'Pass',
          },
        ),
      );

      expect(verdict.decision, ModerationDecision.pass);
    });
  });
}

class _FakeTencentContentModerationClient
    extends TencentContentModerationClient {
  VideoModerationTaskInput? lastVideoInput;

  _FakeTencentContentModerationClient()
      : super(
          const TencentCloudApiConfig(
            secretId: 'fake-secret-id',
            secretKey: 'fake-secret-key',
          ),
          client: _FailOnUnexpectedHttpClient(),
        );

  @override
  Future<VideoModerationTaskResult> createVideoModerationTask(
    VideoModerationTaskInput input,
  ) async {
    lastVideoInput = input;
    return const VideoModerationTaskResult(
      taskId: 'video-task-1',
      requestId: 'video-request-1',
    );
  }
}

class _ErrorPassClient extends TencentContentModerationClient {
  _ErrorPassClient()
      : super(
          const TencentCloudApiConfig(
            secretId: 'fake-secret-id',
            secretKey: 'fake-secret-key',
          ),
          client: _FailOnUnexpectedHttpClient(),
        );

  @override
  Future<VideoModerationTaskDetail> queryModerationTask(
    ModerationTaskQueryInput input,
  ) async {
    return const VideoModerationTaskDetail(
      taskId: 'video-task-error',
      status: ModerationTaskStatus.error,
      requestId: 'req-error-pass',
      decision: ModerationDecision.pass,
      rawResponse: {
        'Status': 'ERROR',
        'Suggestion': 'Pass',
        'ErrorType': 'URL_ERROR',
      },
      hits: [
        ModerationHit(
          decision: ModerationDecision.pass,
          label: ModerationLabel(name: 'Normal'),
        ),
      ],
    );
  }
}

class _FailOnUnexpectedHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('测试不应发起真实 HTTP 请求: ${request.method} ${request.url}');
  }
}
