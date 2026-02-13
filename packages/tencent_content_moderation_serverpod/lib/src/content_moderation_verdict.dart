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
