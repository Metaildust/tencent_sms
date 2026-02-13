import 'package:http/http.dart' as http;
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

import 'tencent_content_moderation_constants.dart';
import 'tencent_content_moderation_exception.dart';
import 'tencent_content_moderation_models.dart';

/// Log callback used by [TencentContentModerationClient].
typedef TencentContentModerationLogCallback = void Function(String message);

/// Typed Tencent content moderation client.
class TencentContentModerationClient {
  final TencentCloudApiClient _apiClient;
  final bool _ownsApiClient;
  final TencentContentModerationLogCallback? _log;

  TencentContentModerationClient(
    TencentCloudApiConfig config, {
    http.Client? client,
    TencentCloudApiClient? apiClient,
    TencentContentModerationLogCallback? log,
  })  : _apiClient = apiClient ?? TencentCloudApiClient(config, client: client),
        _ownsApiClient = apiClient == null,
        _log = log;

  /// Closes owned HTTP resources.
  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }

  /// Moderates plain text with Tencent TMS `TextModeration`.
  Future<TextModerationResult> moderateText(TextModerationInput input) async {
    _ensureValidTextInput(input);
    final envelope = await _sendModerationRequest(
      TencentCloudApiRequest(
        host: TencentContentModerationApiConstants.textHost,
        service: TencentContentModerationApiConstants.textService,
        action: TencentContentModerationApiConstants.textAction,
        version: TencentContentModerationApiConstants.textVersion,
        payload: input.toPayload(),
      ),
    );

    final response = envelope.response;
    final decision = moderationDecisionFromSuggestion(
      _asNonEmptyString(response['Suggestion']),
    );
    final hits = _parseTextHits(response, fallbackDecision: decision);

    return TextModerationResult(
      decision: decision,
      label: _asNonEmptyString(response['Label']) ?? 'Unknown',
      subLabel: _asNonEmptyString(response['SubLabel']),
      score: _asDouble(response['Score']),
      requestId: _requireRequestId(response),
      dataId: _asNonEmptyString(response['DataId']),
      bizType: _asNonEmptyString(response['BizType']),
      keywords: _asStringList(response['Keywords']),
      hits: hits,
      rawResponse: envelope.rawBody,
    );
  }

  /// Moderates image content with Tencent IMS `ImageModeration`.
  Future<ImageModerationResult> moderateImage(
      ImageModerationInput input) async {
    _ensureValidImageInput(input);
    final envelope = await _sendModerationRequest(
      TencentCloudApiRequest(
        host: TencentContentModerationApiConstants.imageHost,
        service: TencentContentModerationApiConstants.imageService,
        action: TencentContentModerationApiConstants.imageAction,
        version: TencentContentModerationApiConstants.imageVersion,
        payload: input.toPayload(),
      ),
    );

    final response = envelope.response;
    final decision = moderationDecisionFromSuggestion(
      _asNonEmptyString(response['Suggestion']),
    );
    final hits = _parseImageHits(response, fallbackDecision: decision);

    return ImageModerationResult(
      decision: decision,
      label: _asNonEmptyString(response['Label']) ?? 'Unknown',
      subLabel: _asNonEmptyString(response['SubLabel']),
      score: _asDouble(response['Score']),
      requestId: _requireRequestId(response),
      dataId: _asNonEmptyString(response['DataId']),
      bizType: _asNonEmptyString(response['BizType']),
      hits: hits,
      rawResponse: envelope.rawBody,
    );
  }

  /// Phase-2 extension point for async audio moderation task creation.
  Future<void> createAudioModerationTask(AudioModerationTaskInput input) {
    throw UnsupportedError(
      'Audio moderation task APIs are planned for phase-2.',
    );
  }

  /// Phase-2 extension point for async video moderation task creation.
  Future<void> createVideoModerationTask(VideoModerationTaskInput input) {
    throw UnsupportedError(
      'Video moderation task APIs are planned for phase-2.',
    );
  }

  /// Phase-2 extension point for async moderation task query.
  Future<void> queryModerationTask(ModerationTaskQueryInput input) {
    throw UnsupportedError(
      'Moderation task query APIs are planned for phase-2.',
    );
  }

  void _ensureValidTextInput(TextModerationInput input) {
    if (input.content.trim().isEmpty) {
      throw const TencentContentModerationConfigException(
        message: 'TextModerationInput.content cannot be empty',
      );
    }
  }

  void _ensureValidImageInput(ImageModerationInput input) {
    final hasUrl = input.hasFileUrl;
    final hasBase64 = input.hasFileBase64;
    if (!hasUrl && !hasBase64) {
      throw const TencentContentModerationConfigException(
        message: 'ImageModerationInput requires fileUrl or fileBase64',
      );
    }
    if (hasUrl && hasBase64) {
      throw const TencentContentModerationConfigException(
        message:
            'ImageModerationInput accepts only one source: fileUrl or fileBase64',
      );
    }
  }

  Future<_ModerationEnvelope> _sendModerationRequest(
    TencentCloudApiRequest request,
  ) async {
    try {
      final rawBody = await _apiClient.post(request);
      final response = _asMap(rawBody['Response']);
      if (response == null) {
        throw const TencentContentModerationResponseException(
          message: 'Response.Response must be a JSON object',
        );
      }

      final error = _asMap(response['Error']);
      if (error != null) {
        throw TencentContentModerationApiException(
          errorCode: _asNonEmptyString(error['Code']) ?? 'UnknownError',
          errorMessage: _asNonEmptyString(error['Message']) ?? 'Unknown error',
          requestId: _asNonEmptyString(response['RequestId']),
        );
      }

      return _ModerationEnvelope(rawBody: rawBody, response: response);
    } on TencentContentModerationException {
      rethrow;
    } on TencentCloudApiHttpException catch (e) {
      _log?.call(
        '[TencentContentModeration] http status error: '
        '${e.statusCode} ${e.responseBody ?? ''}',
      );
      throw TencentContentModerationHttpException(
        statusCode: e.statusCode,
        responseBody: e.responseBody,
        message: e.message,
      );
    } on TencentCloudApiResponseException catch (e) {
      throw TencentContentModerationResponseException(
        message: e.message,
        details: e.details,
      );
    } on TencentCloudApiException catch (e) {
      throw TencentContentModerationException(
        message: e.message,
        code: e.code,
      );
    }
  }

  List<ModerationHit> _parseTextHits(
    Map<String, dynamic> response, {
    required ModerationDecision fallbackDecision,
  }) {
    final details = _asMapList(response['DetailResults']);
    final hits = <ModerationHit>[];
    for (final item in details) {
      hits.add(
        _buildHit(
          item,
          source: 'DetailResults',
          fallbackDecision: fallbackDecision,
        ),
      );
    }

    if (hits.isEmpty) {
      hits.add(
        ModerationHit(
          decision: fallbackDecision,
          label: ModerationLabel(
            name: _asNonEmptyString(response['Label']) ?? 'Unknown',
            subLabel: _asNonEmptyString(response['SubLabel']),
            score: _asDouble(response['Score']),
          ),
          keywords: _asStringList(response['Keywords']),
          raw: response,
        ),
      );
    }
    return hits;
  }

  List<ModerationHit> _parseImageHits(
    Map<String, dynamic> response, {
    required ModerationDecision fallbackDecision,
  }) {
    const listKeys = <String>[
      'LabelResults',
      'ObjectResults',
      'OCRResults',
      'LibResults',
    ];

    final hits = <ModerationHit>[];
    for (final key in listKeys) {
      final rows = _asMapList(response[key]);
      for (final row in rows) {
        hits.add(
          _buildHit(
            row,
            source: key,
            fallbackDecision: fallbackDecision,
          ),
        );
      }
    }

    if (hits.isEmpty) {
      hits.add(
        ModerationHit(
          decision: fallbackDecision,
          label: ModerationLabel(
            name: _asNonEmptyString(response['Label']) ?? 'Unknown',
            subLabel: _asNonEmptyString(response['SubLabel']),
            score: _asDouble(response['Score']),
          ),
          keywords: _extractKeywords(response),
          raw: response,
        ),
      );
    }
    return hits;
  }

  ModerationHit _buildHit(
    Map<String, dynamic> item, {
    required String source,
    required ModerationDecision fallbackDecision,
  }) {
    final suggestion = _asNonEmptyString(item['Suggestion']);
    final decision = suggestion == null
        ? fallbackDecision
        : moderationDecisionFromSuggestion(suggestion);

    final labelName = _asNonEmptyString(item['Label']) ??
        _asNonEmptyString(item['Scene']) ??
        'Unknown';

    return ModerationHit(
      decision: decision,
      label: ModerationLabel(
        name: labelName,
        subLabel: _asNonEmptyString(item['SubLabel']),
        scene: _asNonEmptyString(item['Scene']),
        score: _asDouble(item['Score']),
        libId: _asNonEmptyString(item['LibId']),
        libName: _asNonEmptyString(item['LibName']),
      ),
      keywords: _extractKeywords(item),
      raw: <String, dynamic>{
        'source': source,
        ...item,
      },
    );
  }

  String _requireRequestId(Map<String, dynamic> response) {
    final requestId = _asNonEmptyString(response['RequestId']);
    if (requestId == null) {
      throw const TencentContentModerationResponseException(
        message: 'Response.RequestId is missing',
      );
    }
    return requestId;
  }

  List<String> _extractKeywords(Map<String, dynamic> source) {
    final values = <String>{};

    void addKeyword(dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      values.add(text);
    }

    for (final keyword in _asStringList(source['Keywords'])) {
      addKeyword(keyword);
    }
    addKeyword(source['Keyword']);
    addKeyword(source['Text']);

    for (final detail in _asMapList(source['Details'])) {
      addKeyword(detail['Keyword']);
      addKeyword(detail['Text']);
    }

    return values.toList();
  }

  String? _asNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      final map = _asMap(item);
      if (map != null) {
        result.add(map);
      }
    }
    return result;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }
}

class _ModerationEnvelope {
  final Map<String, dynamic> rawBody;
  final Map<String, dynamic> response;

  const _ModerationEnvelope({
    required this.rawBody,
    required this.response,
  });
}
