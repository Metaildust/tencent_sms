import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

import 'ses_send_response.dart';
import 'tencent_ses_config.dart';
import 'tencent_ses_exception.dart';

/// Log callback function type.
typedef SesLogCallback = void Function(String message);

/// Tencent Cloud SES client.
class TencentSesClient {
  static const _host = 'ses.tencentcloudapi.com';
  static const _service = 'ses';
  static const _version = '2020-10-02';
  static const _maxRecipients = 50;
  static const _maxTemplateDataBytes = 800;

  final TencentSesConfig config;
  final SesLogCallback? _log;
  late final TencentCloudApiClient _apiClient;

  /// Creates a Tencent SES client.
  TencentSesClient(this.config, {http.Client? client, SesLogCallback? log})
    : _log = log {
    final secretId = config.secretId.trim();
    final secretKey = config.secretKey.trim();
    if (secretId.isEmpty || secretKey.isEmpty) {
      throw const TencentSesConfigException(
        message: 'secretId and secretKey cannot be blank',
      );
    }
    _apiClient = TencentCloudApiClient(
      TencentCloudApiConfig(
        secretId: secretId,
        secretKey: secretKey,
        region: config.region,
        token: config.token,
      ),
      client: client,
      log: log == null ? null : (message) => log('[TencentSesApi] $message'),
    );
  }

  /// Closes the underlying HTTP client if owned by this client.
  void close() {
    _apiClient.close();
  }

  /// Sends registration verification code email using configured template.
  Future<SesSendResponse> sendRegistrationVerificationCode({
    required String email,
    required String verificationCode,
    String? requestId,
    bool throwOnError = true,
  }) {
    final templateId = config.templateIdRegister;
    if (templateId == null || templateId <= 0) {
      throw const TencentSesConfigException(
        message: 'Registration template ID is not configured',
      );
    }

    final templateData = _buildVerificationTemplateData(
      verificationCode: verificationCode,
      requestId: requestId,
    );

    return sendTemplateEmail(
      destination: [email],
      subject: config.subjectRegister,
      templateId: templateId,
      templateData: templateData,
      throwOnError: throwOnError,
    );
  }

  /// Sends password reset verification code email using configured template.
  Future<SesSendResponse> sendPasswordResetVerificationCode({
    required String email,
    required String verificationCode,
    String? requestId,
    bool throwOnError = true,
  }) {
    final templateId = config.templateIdResetPassword;
    if (templateId == null || templateId <= 0) {
      throw const TencentSesConfigException(
        message: 'Password reset template ID is not configured',
      );
    }

    final templateData = _buildVerificationTemplateData(
      verificationCode: verificationCode,
      requestId: requestId,
    );

    return sendTemplateEmail(
      destination: [email],
      subject: config.subjectResetPassword,
      templateId: templateId,
      templateData: templateData,
      throwOnError: throwOnError,
    );
  }

  /// Sends a template email via Tencent SES.
  Future<SesSendResponse> sendTemplateEmail({
    required List<String> destination,
    required String subject,
    required int templateId,
    required Map<String, Object?> templateData,
    String? fromEmailAddress,
    String? replyToAddresses,
    int? triggerType,
    bool throwOnError = true,
  }) async {
    final normalizedDestination = _normalizeDestination(destination);
    final normalizedSubject = subject.trim();
    final normalizedFrom = (fromEmailAddress ?? config.fromEmailAddress).trim();
    final normalizedReplyTo = (replyToAddresses ?? config.replyToAddresses)
        ?.trim();
    final normalizedTriggerType = triggerType ?? config.defaultTriggerType;

    if (normalizedFrom.isEmpty) {
      throw const TencentSesConfigException(
        message: 'fromEmailAddress cannot be empty',
      );
    }
    if (normalizedSubject.isEmpty) {
      throw const TencentSesConfigException(message: 'subject cannot be empty');
    }
    if (templateId <= 0) {
      throw const TencentSesConfigException(
        message: 'templateId must be greater than 0',
      );
    }
    if (templateData.isEmpty) {
      throw const TencentSesConfigException(
        message: 'templateData cannot be empty',
      );
    }
    if (normalizedTriggerType != 0 && normalizedTriggerType != 1) {
      throw const TencentSesConfigException(
        message: 'triggerType must be 0 or 1',
      );
    }

    final templateDataJson = jsonEncode(templateData);
    final templateDataLength = utf8.encode(templateDataJson).length;
    if (templateDataLength > _maxTemplateDataBytes) {
      throw TencentSesConfigException(
        message:
            'templateData exceeds ${_maxTemplateDataBytes} bytes (actual: $templateDataLength)',
      );
    }

    final payload = <String, dynamic>{
      'FromEmailAddress': normalizedFrom,
      'Destination': normalizedDestination,
      'Subject': normalizedSubject,
      'Template': <String, dynamic>{
        'TemplateID': templateId,
        'TemplateData': templateDataJson,
      },
      'TriggerType': normalizedTriggerType,
      if (normalizedReplyTo != null && normalizedReplyTo.isNotEmpty)
        'ReplyToAddresses': normalizedReplyTo,
    };

    try {
      final jsonBody = await _apiClient.post(
        TencentCloudApiRequest(
          host: _host,
          service: _service,
          action: 'SendEmail',
          version: _version,
          payload: payload,
        ),
      );
      final response = SesSendResponse.fromJson(jsonBody);
      if (!response.isOk && throwOnError) {
        _log?.call(
          '[TencentSes] sendTemplateEmail failed: '
          'requestId=${response.requestId}, '
          'error=${response.error?.code ?? 'UnknownError'} '
          '${response.error?.message ?? ''}',
        );
        throw TencentSesSendException(
          message:
              'SES send failed: ${response.error?.message ?? 'Unknown error'}',
          code: response.error?.code,
        );
      }
      return response;
    } on TencentCloudApiHttpException catch (e) {
      throw TencentSesHttpException(
        statusCode: e.statusCode,
        message: 'SES service request failed',
      );
    } on TencentCloudApiResponseException catch (e) {
      _log?.call('[TencentSes] invalid response: $e');
      throw TencentSesSendException(
        message: 'SES send failed: ${e.message}',
        code: e.code,
      );
    } on TencentCloudApiException catch (e) {
      _log?.call('[TencentSes] api error: $e');
      throw TencentSesSendException(
        message: 'SES send failed: ${e.message}',
        code: e.code,
      );
    }
  }

  List<String> _normalizeDestination(List<String> destination) {
    final result = destination.map((e) => e.trim()).where((e) => e.isNotEmpty);
    final normalized = result.toList();
    if (normalized.isEmpty) {
      throw const TencentSesConfigException(
        message: 'destination cannot be empty',
      );
    }
    if (normalized.length > _maxRecipients) {
      throw TencentSesConfigException(
        message: 'destination exceeds $_maxRecipients recipients',
      );
    }
    return normalized;
  }

  Map<String, Object?> _buildVerificationTemplateData({
    required String verificationCode,
    String? requestId,
  }) {
    final normalizedCode = verificationCode.trim();
    if (normalizedCode.isEmpty) {
      throw const TencentSesConfigException(
        message: 'verificationCode cannot be empty',
      );
    }

    final data = <String, Object?>{config.templateDataCodeKey: normalizedCode};
    final requestIdKey = config.templateDataRequestIdKey?.trim();
    final normalizedRequestId = requestId?.trim();
    if (requestIdKey != null &&
        requestIdKey.isNotEmpty &&
        normalizedRequestId != null &&
        normalizedRequestId.isNotEmpty) {
      data[requestIdKey] = normalizedRequestId;
    }
    return data;
  }
}
