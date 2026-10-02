import 'package:tencent_content_moderation/tencent_content_moderation.dart';

/// Domain-level moderation verdict for server usage.
class ContentModerationVerdict {
  final String contentType;
  final ModerationDecision decision;
  final String requestId;
  final String label;
  final String? subLabel;
  final double? score;
  final String? dataId;
  final String? bizType;
  final List<ModerationHit> hits;
  final Map<String, dynamic> rawResponse;

  const ContentModerationVerdict({
    required this.contentType,
    required this.decision,
    required this.requestId,
    required this.label,
    required this.rawResponse,
    this.subLabel,
    this.score,
    this.dataId,
    this.bizType,
    this.hits = const [],
  });

  factory ContentModerationVerdict.fromTextResult(TextModerationResult result) {
    return ContentModerationVerdict(
      contentType: 'text',
      decision: result.decision,
      requestId: result.requestId,
      label: result.label,
      subLabel: result.subLabel,
      score: result.score,
      dataId: result.dataId,
      bizType: result.bizType,
      hits: result.hits,
      rawResponse: result.rawResponse,
    );
  }

  factory ContentModerationVerdict.fromImageResult(
    ImageModerationResult result,
  ) {
    return ContentModerationVerdict(
      contentType: 'image',
      decision: result.decision,
      requestId: result.requestId,
      label: result.label,
      subLabel: result.subLabel,
      score: result.score,
      dataId: result.dataId,
      bizType: result.bizType,
      hits: result.hits,
      rawResponse: result.rawResponse,
    );
  }

  bool get isPass => decision == ModerationDecision.pass;
  bool get isReview => decision == ModerationDecision.review;
  bool get isBlock => decision == ModerationDecision.block;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'contentType': contentType,
      'decision': decision.name,
      'requestId': requestId,
      'label': label,
      'subLabel': subLabel,
      'score': score,
      'dataId': dataId,
      'bizType': bizType,
      'hits': hits.map((e) => e.toJson()).toList(),
      'rawResponse': rawResponse,
    };
  }
}

/// Domain-level video moderation task verdict for async workflows.
class VideoModerationTaskVerdict {
  final String contentType;
  final String taskId;
  final ModerationTaskStatus status;
  final ModerationDecision? decision;
  final String requestId;
  final String? dataId;
  final String? bizType;
  final String? label;
  final String? subLabel;
  final double? score;
  final List<ModerationHit> hits;
  final Map<String, dynamic> rawResponse;

  const VideoModerationTaskVerdict({
    required this.contentType,
    required this.taskId,
    required this.status,
    required this.requestId,
    required this.rawResponse,
    this.decision,
    this.dataId,
    this.bizType,
    this.label,
    this.subLabel,
    this.score,
    this.hits = const [],
  });

  factory VideoModerationTaskVerdict.fromVideoTaskDetail(
    VideoModerationTaskDetail detail,
  ) {
    // 不把上游抄来的通过或复审原样留下：任务失败或结构化错误时改为拦截。
    final failed = videoTaskFailed(
      status: detail.status,
      payload: detail.rawResponse,
    );
    final decision = closedVideoDecision(
      status: detail.status,
      decision: detail.decision,
      payload: detail.rawResponse,
    );
    return VideoModerationTaskVerdict(
      contentType: 'video',
      taskId: detail.taskId,
      status: detail.status,
      decision: decision,
      requestId: detail.requestId,
      dataId: detail.dataId,
      bizType: detail.bizType,
      label: detail.label,
      subLabel: detail.subLabel,
      score: detail.score,
      hits: closedVideoHits(detail.hits, failed: failed),
      rawResponse: detail.rawResponse,
    );
  }

  bool get isFinished => status == ModerationTaskStatus.finish;
  bool get isProcessing =>
      status == ModerationTaskStatus.pending ||
      status == ModerationTaskStatus.running;
  bool get isError => status == ModerationTaskStatus.error;
  bool get isCancelled => status == ModerationTaskStatus.cancelled;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'contentType': contentType,
      'taskId': taskId,
      'status': status.name,
      'decision': decision?.name,
      'requestId': requestId,
      'dataId': dataId,
      'bizType': bizType,
      'label': label,
      'subLabel': subLabel,
      'score': score,
      'hits': hits.map((e) => e.toJson()).toList(),
      'rawResponse': rawResponse,
    };
  }
}
