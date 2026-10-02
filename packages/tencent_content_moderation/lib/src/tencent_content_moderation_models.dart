import 'dart:convert';

/// Normalized moderation decision.
enum ModerationDecision {
  pass,
  review,
  block,
}

/// Maps Tencent `Suggestion` to [ModerationDecision].
ModerationDecision moderationDecisionFromSuggestion(String? suggestion) {
  switch ((suggestion ?? '').trim().toLowerCase()) {
    case 'pass':
      return ModerationDecision.pass;
    case 'block':
      return ModerationDecision.block;
    case 'review':
    default:
      return ModerationDecision.review;
  }
}

/// A normalized moderation label.
class ModerationLabel {
  final String name;
  final String? subLabel;
  final String? scene;
  final double? score;
  final String? libId;
  final String? libName;

  const ModerationLabel({
    required this.name,
    this.subLabel,
    this.scene,
    this.score,
    this.libId,
    this.libName,
  });

  Map<String, dynamic> toJson() {
    return _compactMap({
      'name': name,
      'subLabel': subLabel,
      'scene': scene,
      'score': score,
      'libId': libId,
      'libName': libName,
    });
  }
}

/// A normalized moderation hit detail from Tencent response.
class ModerationHit {
  final ModerationDecision decision;
  final ModerationLabel label;
  final List<String> keywords;
  final Map<String, dynamic> raw;

  const ModerationHit({
    required this.decision,
    required this.label,
    this.keywords = const [],
    this.raw = const {},
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'decision': decision.name,
      'label': label.toJson(),
      'keywords': keywords,
      'raw': raw,
    };
  }
}

/// Shared result fields for moderation APIs.
abstract class ModerationResultBase {
  final ModerationDecision decision;
  final String label;
  final String? subLabel;
  final double? score;
  final String requestId;
  final String? dataId;
  final String? bizType;
  final List<ModerationHit> hits;
  final Map<String, dynamic> rawResponse;

  const ModerationResultBase({
    required this.decision,
    required this.label,
    required this.requestId,
    required this.rawResponse,
    this.subLabel,
    this.score,
    this.dataId,
    this.bizType,
    this.hits = const [],
  });

  bool get isPass => decision == ModerationDecision.pass;
  bool get isReview => decision == ModerationDecision.review;
  bool get isBlock => decision == ModerationDecision.block;

  Map<String, dynamic> toJson() {
    return _compactMap({
      'decision': decision.name,
      'label': label,
      'subLabel': subLabel,
      'score': score,
      'requestId': requestId,
      'dataId': dataId,
      'bizType': bizType,
      'hits': hits.map((e) => e.toJson()).toList(),
      'rawResponse': rawResponse,
    });
  }
}

/// Result of Tencent text moderation.
class TextModerationResult extends ModerationResultBase {
  final List<String> keywords;

  const TextModerationResult({
    required super.decision,
    required super.label,
    required super.requestId,
    required super.rawResponse,
    super.subLabel,
    super.score,
    super.dataId,
    super.bizType,
    super.hits = const [],
    this.keywords = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...super.toJson(),
      'keywords': keywords,
    };
  }
}

/// Result of Tencent image moderation.
class ImageModerationResult extends ModerationResultBase {
  const ImageModerationResult({
    required super.decision,
    required super.label,
    required super.requestId,
    required super.rawResponse,
    super.subLabel,
    super.score,
    super.dataId,
    super.bizType,
    super.hits = const [],
  });
}

/// Optional user metadata for moderation context.
class ModerationUser {
  final String? userId;
  final String? nickname;
  final String? accountType;
  final String? email;
  final String? phone;
  final String? ip;

  const ModerationUser({
    this.userId,
    this.nickname,
    this.accountType,
    this.email,
    this.phone,
    this.ip,
  });

  Map<String, dynamic> toJson() {
    return _compactMap({
      'UserId': userId,
      'Nickname': nickname,
      'AccountType': accountType,
      'Email': email,
      'Phone': phone,
      'Ip': ip,
    });
  }
}

/// Optional device metadata for moderation context.
class ModerationDevice {
  final String? ip;
  final String? mac;
  final String? imei;
  final String? idfa;
  final String? idfv;
  final String? deviceToken;
  final String? platform;

  const ModerationDevice({
    this.ip,
    this.mac,
    this.imei,
    this.idfa,
    this.idfv,
    this.deviceToken,
    this.platform,
  });

  Map<String, dynamic> toJson() {
    return _compactMap({
      'Ip': ip,
      'Mac': mac,
      'IMEI': imei,
      'IDFA': idfa,
      'IDFV': idfv,
      'DeviceToken': deviceToken,
      'Platform': platform,
    });
  }
}

/// Input for Tencent text moderation.
class TextModerationInput {
  final String content;
  final String? bizType;
  final String? dataId;
  final ModerationUser? user;
  final ModerationDevice? device;

  const TextModerationInput({
    required this.content,
    this.bizType,
    this.dataId,
    this.user,
    this.device,
  });

  Map<String, dynamic> toPayload() {
    return _compactMap({
      'Content': base64Encode(utf8.encode(content)),
      'BizType': bizType,
      'DataId': dataId,
      'User': user?.toJson(),
      'Device': device?.toJson(),
    });
  }
}

/// Input for Tencent image moderation.
class ImageModerationInput {
  final String? fileUrl;
  final String? fileBase64;
  final String? bizType;
  final String? dataId;
  final ModerationUser? user;
  final ModerationDevice? device;

  const ImageModerationInput({
    this.fileUrl,
    this.fileBase64,
    this.bizType,
    this.dataId,
    this.user,
    this.device,
  });

  bool get hasFileUrl => fileUrl != null && fileUrl!.trim().isNotEmpty;
  bool get hasFileBase64 => fileBase64 != null && fileBase64!.trim().isNotEmpty;

  Map<String, dynamic> toPayload() {
    return _compactMap({
      'FileUrl': fileUrl,
      'FileContent': fileBase64,
      'BizType': bizType,
      'DataId': dataId,
      'User': user?.toJson(),
      'Device': device?.toJson(),
    });
  }
}

class AudioModerationTaskInput {
  final String? fileUrl;
  final String? fileBase64;
  final String? bizType;
  final String? dataId;
  final String? callbackUrl;
  final ModerationUser? user;
  final ModerationDevice? device;

  const AudioModerationTaskInput({
    this.fileUrl,
    this.fileBase64,
    this.bizType,
    this.dataId,
    this.callbackUrl,
    this.user,
    this.device,
  });

  Map<String, dynamic> toPayload() {
    return _compactMap({
      'FileUrl': fileUrl,
      'FileContent': fileBase64,
      'BizType': bizType,
      'DataId': dataId,
      'CallbackUrl': callbackUrl,
      'User': user?.toJson(),
      'Device': device?.toJson(),
    });
  }
}

/// Async video moderation create-task input.
///
/// Video moderation only accepts a publicly reachable [fileUrl]. The previous
/// `storageInfo` (`Type=COS + BucketInfo`) cross-account direct-input mode was
/// removed in 0.2.0 because Tencent Cloud VM evaluates that path with internal
/// STS credentials whose permission resolution is not stable across regions
/// and account combinations, producing a `URL_ERROR / 403 Forbidden` upstream
/// error coupled with a misleading `Suggestion=Pass` default that masks the
/// failure. Callers that previously relied on `StorageInfo.cos(...)` must
/// generate a presigned `GET` URL on their own COS bucket and pass it as
/// [fileUrl]. See `CHANGELOG.md` for migration details.
class VideoModerationTaskInput {
  final String? fileUrl;
  final String? bizType;
  final String? dataId;
  final String? callbackUrl;
  final String? seed;
  final ModerationUser? user;
  final ModerationDevice? device;

  const VideoModerationTaskInput({
    this.fileUrl,
    this.bizType,
    this.dataId,
    this.callbackUrl,
    this.seed,
    this.user,
    this.device,
  });

  Map<String, dynamic> toPayload() {
    return _compactMap({
      'BizType': bizType,
      'Type': 'VIDEO',
      'Tasks': [
        _compactMap({
          'DataId': dataId,
          'Input': _compactMap({
            'Type': 'URL',
            // 与 client._ensureValidVideoTaskInput 的 trim 语义保持一致，
            // 避免调用方传入带前后空白的 URL 导致腾讯云 VM 拉流时 404/403。
            'Url': fileUrl?.trim(),
          }),
        }),
      ],
      'CallbackUrl': callbackUrl,
      'Seed': seed,
      'User': user?.toJson(),
      'Device': device?.toJson(),
    });
  }
}

/// Phase-2 extension point: async moderation task query input.
class ModerationTaskQueryInput {
  final String taskId;

  const ModerationTaskQueryInput({required this.taskId});

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{'TaskId': taskId};
  }
}

/// Normalized async task status for moderation jobs.
enum ModerationTaskStatus {
  pending,
  running,
  finish,
  error,
  cancelled,
  unknown,
}

/// Maps provider task status value to [ModerationTaskStatus].
ModerationTaskStatus moderationTaskStatusFromValue(String? status) {
  switch ((status ?? '').trim().toLowerCase()) {
    case 'pending':
      return ModerationTaskStatus.pending;
    case 'running':
    case 'processing':
      return ModerationTaskStatus.running;
    case 'finish':
    case 'finished':
    case 'done':
      return ModerationTaskStatus.finish;
    case 'error':
    case 'failed':
    case 'fail':
      return ModerationTaskStatus.error;
    case 'cancelled':
    case 'canceled':
      return ModerationTaskStatus.cancelled;
    default:
      return ModerationTaskStatus.unknown;
  }
}

/// 任务状态失败，或载荷里带结构化任务错误时，为真。
///
/// 结构化错误只认非空的 `ErrorType`、`ErrorDescription`（含嵌在 `Task` 下），
/// 以及 `Errors[]` 元素的非空 `Code`。空白不算。正文、OCR、ASR 里的
/// `URL_ERROR` 子串不算。状态为 error / cancelled 时直接为真。
bool videoTaskFailed({
  required ModerationTaskStatus status,
  Map<String, dynamic>? payload,
  Map<String, dynamic>? extra,
}) {
  if (status == ModerationTaskStatus.error ||
      status == ModerationTaskStatus.cancelled) {
    return true;
  }
  return hasStructuredVideoTaskError(payload) ||
      hasStructuredVideoTaskError(extra);
}

/// 失败关闭：任务失败或响应带结构化错误时，通过和复审都改为拦截。
///
/// block 与空建议保持原值。进行中且没有结构化错误时，通过仍保持通过。
ModerationDecision? closedVideoDecision({
  required ModerationTaskStatus status,
  ModerationDecision? decision,
  Map<String, dynamic>? payload,
  Map<String, dynamic>? extra,
}) {
  if (decision != ModerationDecision.pass &&
      decision != ModerationDecision.review) {
    return decision;
  }
  if (!videoTaskFailed(status: status, payload: payload, extra: extra)) {
    return decision;
  }
  return ModerationDecision.block;
}

/// 失败时，命中明细里的通过和复审都改为拦截。
List<ModerationHit> closedVideoHits(
  List<ModerationHit> hits, {
  required bool failed,
}) {
  if (!failed) return hits;
  return [
    for (final hit in hits)
      if (hit.decision == ModerationDecision.pass ||
          hit.decision == ModerationDecision.review)
        ModerationHit(
          decision: ModerationDecision.block,
          label: hit.label,
          keywords: hit.keywords,
          raw: hit.raw,
        )
      else
        hit,
  ];
}

/// 载荷里是否有结构化任务错误。
///
/// 任一对象键 `ErrorType`、`ErrorDescription`（含嵌套），或 `Errors[]` 元素的
/// `Code`，trim 后非空即算。任意字符串里的 `URL_ERROR` 子串不算。
bool hasStructuredVideoTaskError(Object? node) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if ((key == 'ErrorType' || key == 'ErrorDescription') &&
          _nonBlank(value)) {
        return true;
      }
      if (key == 'Errors' && value is List) {
        for (final item in value) {
          if (item is Map && _nonBlank(item['Code'])) {
            return true;
          }
        }
      }
      if (hasStructuredVideoTaskError(value)) return true;
    }
    return false;
  }
  if (node is List) {
    for (final item in node) {
      if (hasStructuredVideoTaskError(item)) return true;
    }
  }
  return false;
}

/// 回调或轮询保存的 JSON 原文，按 [hasStructuredVideoTaskError] 判定。
///
/// 空串或无法解析时视为没有结构化错误，避免把截断正文误当成任务失败。
bool rawResultHasStructuredVideoTaskError(String? rawResult) {
  final text = rawResult?.trim();
  if (text == null || text.isEmpty) return false;
  try {
    return hasStructuredVideoTaskError(jsonDecode(text));
  } on FormatException {
    return false;
  }
}

bool _nonBlank(Object? value) {
  if (value == null) return false;
  return value.toString().trim().isNotEmpty;
}

/// Result of video moderation task creation.
class VideoModerationTaskResult {
  final String taskId;
  final String requestId;
  final String? dataId;
  final Map<String, dynamic> rawResponse;

  const VideoModerationTaskResult({
    required this.taskId,
    required this.requestId,
    this.dataId,
    this.rawResponse = const {},
  });

  Map<String, dynamic> toJson() {
    return _compactMap({
      'taskId': taskId,
      'requestId': requestId,
      'dataId': dataId,
      'rawResponse': rawResponse,
    });
  }
}

/// Result of video moderation task query.
class VideoModerationTaskDetail {
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

  const VideoModerationTaskDetail({
    required this.taskId,
    required this.status,
    required this.requestId,
    this.decision,
    this.dataId,
    this.bizType,
    this.label,
    this.subLabel,
    this.score,
    this.hits = const [],
    this.rawResponse = const {},
  });

  bool get isFinished => status == ModerationTaskStatus.finish;
  bool get isProcessing =>
      status == ModerationTaskStatus.pending ||
      status == ModerationTaskStatus.running;
  bool get isError => status == ModerationTaskStatus.error;
  bool get isCancelled => status == ModerationTaskStatus.cancelled;

  Map<String, dynamic> toJson() {
    return _compactMap({
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
    });
  }
}

Map<String, dynamic> _compactMap(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final value = entry.value;
    if (value == null) continue;
    if (value is String && value.isEmpty) continue;
    result[entry.key] = value;
  }
  return result;
}
