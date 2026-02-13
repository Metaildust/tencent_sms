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

/// Phase-2 extension point: async audio moderation create-task input.
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

/// Phase-2 extension point: async video moderation create-task input.
class VideoModerationTaskInput {
  final String fileUrl;
  final String? bizType;
  final String? dataId;
  final String? callbackUrl;
  final ModerationUser? user;
  final ModerationDevice? device;

  const VideoModerationTaskInput({
    required this.fileUrl,
    this.bizType,
    this.dataId,
    this.callbackUrl,
    this.user,
    this.device,
  });

  Map<String, dynamic> toPayload() {
    return _compactMap({
      'FileUrl': fileUrl,
      'BizType': bizType,
      'DataId': dataId,
      'CallbackUrl': callbackUrl,
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
