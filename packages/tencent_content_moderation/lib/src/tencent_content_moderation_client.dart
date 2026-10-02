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
  })  : _apiClient = _openClient(config, client: client, apiClient: apiClient),
        _ownsApiClient = apiClient == null,
        _log = log;

  /// 密钥去掉空白后为空则在建客户端时失败，请求不会发出。
  static TencentCloudApiClient _openClient(
    TencentCloudApiConfig config, {
    required http.Client? client,
    required TencentCloudApiClient? apiClient,
  }) {
    final secretId = config.secretId.trim();
    final secretKey = config.secretKey.trim();
    if (secretId.isEmpty || secretKey.isEmpty) {
      throw const TencentContentModerationConfigException(
        message: 'secretId and secretKey cannot be blank',
      );
    }
    final checked =
        (secretId == config.secretId && secretKey == config.secretKey)
            ? config
            : TencentCloudApiConfig(
                secretId: secretId,
                secretKey: secretKey,
                region: config.region,
                token: config.token,
              );
    return apiClient ?? TencentCloudApiClient(checked, client: client);
  }

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

  /// Creates async video moderation task with Tencent VM API.
  Future<VideoModerationTaskResult> createVideoModerationTask(
    VideoModerationTaskInput input,
  ) async {
    _ensureValidVideoTaskInput(input);
    final envelope = await _sendModerationRequest(
      TencentCloudApiRequest(
        host: TencentContentModerationApiConstants.videoHost,
        service: TencentContentModerationApiConstants.videoService,
        action: TencentContentModerationApiConstants.videoAction,
        version: TencentContentModerationApiConstants.videoVersion,
        payload: input.toPayload(),
      ),
    );

    final response = envelope.response;
    final taskId = _resolveTaskId(response);
    if (taskId == null) {
      throw TencentContentModerationResponseException(
        message: 'Video moderation task id is missing',
        details: envelope.rawBody.toString(),
      );
    }

    return VideoModerationTaskResult(
      taskId: taskId,
      requestId: _requireRequestId(response),
      dataId: _resolveTaskDataId(response),
      rawResponse: envelope.rawBody,
    );
  }

  /// Queries async moderation task status with Tencent VM API.
  Future<VideoModerationTaskDetail> queryModerationTask(
    ModerationTaskQueryInput input,
  ) async {
    _ensureValidTaskQueryInput(input);
    final envelope = await _sendModerationRequest(
      TencentCloudApiRequest(
        host: TencentContentModerationApiConstants.videoHost,
        service: TencentContentModerationApiConstants.videoService,
        action: TencentContentModerationApiConstants.videoQueryAction,
        version: TencentContentModerationApiConstants.videoVersion,
        payload: input.toPayload(),
      ),
    );

    final response = envelope.response;
    final taskPayload = _extractTaskPayload(response);
    final statusText = _asNonEmptyString(taskPayload['Status']) ??
        _asNonEmptyString(response['Status']);
    final status = moderationTaskStatusFromValue(statusText);
    final decisionText = _asNonEmptyString(taskPayload['Suggestion']) ??
        _asNonEmptyString(response['Suggestion']);
    // 总建议缺失、空串或只有空白时落到复审。明细里的拦截不抬成整单。
    final suggested = moderationDecisionFromSuggestion(decisionText);
    // 任务失败或响应带结构化错误时，建议为通过或复审都不能保持原值。
    final failed = videoTaskFailed(
      status: status,
      payload: taskPayload,
      extra: response,
    );
    final decision = closedVideoDecision(
      status: status,
      decision: suggested,
      payload: taskPayload,
      extra: response,
    );
    final fallbackDecision = decision ?? ModerationDecision.review;
    final hits = closedVideoHits(
      _parseVideoTaskHits(
        taskPayload,
        fallbackDecision: fallbackDecision,
      ),
      failed: failed,
    );

    final taskId = _asNonEmptyString(taskPayload['TaskId']) ??
        _asNonEmptyString(taskPayload['TaskID']) ??
        _asNonEmptyString(response['TaskId']) ??
        input.taskId;

    return VideoModerationTaskDetail(
      taskId: taskId,
      status: status,
      decision: decision,
      requestId: _requireRequestId(response),
      dataId: _asNonEmptyString(taskPayload['DataId']) ??
          _asNonEmptyString(response['DataId']),
      bizType: _asNonEmptyString(taskPayload['BizType']) ??
          _asNonEmptyString(response['BizType']),
      label: _asNonEmptyString(taskPayload['Label']) ??
          _asNonEmptyString(response['Label']),
      subLabel: _asNonEmptyString(taskPayload['SubLabel']) ??
          _asNonEmptyString(response['SubLabel']),
      score: _asDouble(taskPayload['Score']) ?? _asDouble(response['Score']),
      hits: hits,
      rawResponse: envelope.rawBody,
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

  void _ensureValidVideoTaskInput(VideoModerationTaskInput input) {
    final trimmed = _asNonEmptyString(input.fileUrl);
    if (trimmed == null) {
      throw const TencentContentModerationConfigException(
        message: 'VideoModerationTaskInput.fileUrl cannot be empty',
      );
    }
    final uri = Uri.tryParse(trimmed);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        !uri.hasScheme ||
        (scheme != 'http' && scheme != 'https')) {
      throw const TencentContentModerationConfigException(
        message: 'VideoModerationTaskInput.fileUrl must be a valid http(s) URL',
      );
    }
  }

  void _ensureValidTaskQueryInput(ModerationTaskQueryInput input) {
    if (input.taskId.trim().isEmpty) {
      throw const TencentContentModerationConfigException(
        message: 'ModerationTaskQueryInput.taskId cannot be empty',
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

  List<ModerationHit> _parseVideoTaskHits(
    Map<String, dynamic> response, {
    required ModerationDecision fallbackDecision,
  }) {
    const listKeys = <String>[
      'Labels',
      'LabelResults',
      'ObjectResults',
      'OCRResults',
      'AsrResults',
      'LibResults',
      'Results',
      'DetailResults',
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
      final labelName = _asNonEmptyString(response['Label']) ??
          _asNonEmptyString(response['Scene']) ??
          _asNonEmptyString(response['Suggestion']);
      if (labelName != null) {
        hits.add(
          ModerationHit(
            decision: fallbackDecision,
            label: ModerationLabel(
              name: labelName,
              subLabel: _asNonEmptyString(response['SubLabel']),
              scene: _asNonEmptyString(response['Scene']),
              score: _asDouble(response['Score']),
            ),
            keywords: _extractKeywords(response),
            raw: response,
          ),
        );
      }
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

  static String? _asNonEmptyString(dynamic value) {
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

  String? _resolveTaskId(Map<String, dynamic> response) {
    final data = _asMap(response['Data']);
    return _asNonEmptyString(response['TaskId']) ??
        _asNonEmptyString(response['TaskID']) ??
        _asNonEmptyString(data?['TaskId']) ??
        _asNonEmptyString(data?['TaskID']) ??
        _resolveTaskIdFromRows(response['Tasks']) ??
        _resolveTaskIdFromRows(data?['Tasks']) ??
        _resolveTaskIdFromRows(response['Results']) ??
        _resolveTaskIdFromRows(data?['Results']);
  }

  String? _resolveTaskDataId(Map<String, dynamic> response) {
    final data = _asMap(response['Data']);
    return _asNonEmptyString(response['DataId']) ??
        _asNonEmptyString(data?['DataId']) ??
        _resolveFieldFromRows(response['Results'], 'DataId') ??
        _resolveFieldFromRows(data?['Results'], 'DataId') ??
        _resolveFieldFromRows(response['Tasks'], 'DataId') ??
        _resolveFieldFromRows(data?['Tasks'], 'DataId');
  }

  String? _resolveTaskIdFromRows(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      final row = _asMap(item);
      if (row == null) continue;
      final taskId =
          _asNonEmptyString(row['TaskId']) ?? _asNonEmptyString(row['TaskID']);
      if (taskId != null) return taskId;
    }
    return null;
  }

  String? _resolveFieldFromRows(dynamic value, String field) {
    if (value is! List) return null;
    for (final item in value) {
      final row = _asMap(item);
      if (row == null) continue;
      final resolved = _asNonEmptyString(row[field]);
      if (resolved != null) return resolved;
    }
    return null;
  }

  Map<String, dynamic> _extractTaskPayload(Map<String, dynamic> response) {
    final directTask = _asMap(response['Task']);
    if (directTask != null) return directTask;
    final taskInfo = _asMap(response['TaskInfo']);
    if (taskInfo != null) return taskInfo;
    final data = _asMap(response['Data']);
    if (data != null) return data;
    final result = _asMap(response['Result']);
    if (result != null) return result;
    final firstTask = _firstTaskFromRows(response['Tasks']);
    if (firstTask != null) return firstTask;
    return response;
  }

  Map<String, dynamic>? _firstTaskFromRows(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      final row = _asMap(item);
      if (row != null) return row;
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
