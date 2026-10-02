import 'package:tencent_content_moderation/tencent_content_moderation.dart';

import 'content_moderation_verdict.dart';
import 'tencent_content_moderation_config_serverpod.dart';

/// Server-oriented facade for Tencent content moderation.
class ContentModerationService {
  final TencentContentModerationClient _client;
  final bool _ownsClient;
  final String? _defaultTextBizType;
  final String? _defaultImageBizType;
  final String? _defaultVideoBizType;

  ContentModerationService(
    TencentContentModerationServerpodConfig config, {
    TencentContentModerationClient? client,
  })  : _client = client ?? TencentContentModerationClient(config.apiConfig),
        _ownsClient = client == null,
        _defaultTextBizType = _normalize(config.defaultTextBizType),
        _defaultImageBizType = _normalize(config.defaultImageBizType),
        _defaultVideoBizType = _normalize(config.defaultVideoBizType);

  /// Closes owned resources.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Reviews text content and returns a domain-level verdict.
  Future<ContentModerationVerdict> reviewText(
    String content, {
    String? bizType,
    String? dataId,
    ModerationUser? user,
    ModerationDevice? device,
  }) async {
    final result = await _client.moderateText(
      TextModerationInput(
        content: content,
        bizType: _resolveBizType(bizType, _defaultTextBizType),
        dataId: _normalize(dataId),
        user: user,
        device: device,
      ),
    );
    return ContentModerationVerdict.fromTextResult(result);
  }

  /// Reviews image by URL and returns a domain-level verdict.
  Future<ContentModerationVerdict> reviewImageUrl(
    String imageUrl, {
    String? bizType,
    String? dataId,
    ModerationUser? user,
    ModerationDevice? device,
  }) async {
    final result = await _client.moderateImage(
      ImageModerationInput(
        fileUrl: imageUrl,
        bizType: _resolveBizType(bizType, _defaultImageBizType),
        dataId: _normalize(dataId),
        user: user,
        device: device,
      ),
    );
    return ContentModerationVerdict.fromImageResult(result);
  }

  /// Submits async video moderation task and returns task metadata.
  ///
  /// Video moderation is URL-only since 0.2.0. Pass a publicly reachable
  /// URL (e.g. a presigned `GET` URL on the caller-owned COS bucket) as
  /// [videoUrl]. The previous COS direct-input helper
  /// `submitVideoModerationForStorage` was removed; see
  /// `package:tencent_content_moderation` 0.2.0 CHANGELOG for migration.
  Future<VideoModerationTaskResult> submitVideoModeration(
    String videoUrl, {
    String? bizType,
    String? dataId,
    String? callbackUrl,
    String? seed,
    ModerationUser? user,
    ModerationDevice? device,
  }) async {
    return _client.createVideoModerationTask(
      VideoModerationTaskInput(
        fileUrl: videoUrl,
        bizType: _resolveBizType(bizType, _defaultVideoBizType),
        dataId: _normalize(dataId),
        callbackUrl: _normalize(callbackUrl),
        seed: _normalize(seed),
        user: user,
        device: device,
      ),
    );
  }

  /// Queries async video moderation task and returns domain-level verdict.
  Future<VideoModerationTaskVerdict> queryVideoModeration(String taskId) async {
    final detail = await _client.queryModerationTask(
      ModerationTaskQueryInput(taskId: taskId),
    );
    return VideoModerationTaskVerdict.fromVideoTaskDetail(detail);
  }

  String? _resolveBizType(String? override, String? fallback) {
    return _normalize(override) ?? fallback;
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
