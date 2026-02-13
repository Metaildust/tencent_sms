/// Base exception for content moderation failures.
class TencentContentModerationException implements Exception {
  final String message;
  final String? code;
  final String? requestId;

  const TencentContentModerationException({
    required this.message,
    this.code,
    this.requestId,
  });

  @override
  String toString() {
    final codeText = code == null ? '' : ' (code: $code)';
    final requestText = requestId == null ? '' : ' (requestId: $requestId)';
    return 'TencentContentModerationException: $message$codeText$requestText';
  }
}

/// Invalid client/input setup before request is sent.
class TencentContentModerationConfigException
    extends TencentContentModerationException {
  const TencentContentModerationConfigException({
    required super.message,
    super.requestId,
    super.code = 'CONFIG_ERROR',
  });
}

/// HTTP layer failures.
class TencentContentModerationHttpException
    extends TencentContentModerationException {
  final int statusCode;
  final String? responseBody;

  const TencentContentModerationHttpException({
    required this.statusCode,
    required super.message,
    this.responseBody,
    super.requestId,
    super.code = 'HTTP_ERROR',
  });

  @override
  String toString() =>
      'TencentContentModerationHttpException: HTTP $statusCode - $message';
}

/// Tencent Cloud API business error (`Response.Error`).
class TencentContentModerationApiException
    extends TencentContentModerationException {
  final String errorCode;
  final String errorMessage;

  const TencentContentModerationApiException({
    required this.errorCode,
    required this.errorMessage,
    super.requestId,
  }) : super(
          message: errorMessage,
          code: errorCode,
        );

  @override
  String toString() {
    final requestText = requestId == null ? '' : ' (requestId: $requestId)';
    return 'TencentContentModerationApiException: '
        '$errorCode - $errorMessage$requestText';
  }
}

/// Response structure / JSON shape failures.
class TencentContentModerationResponseException
    extends TencentContentModerationException {
  final String? details;

  const TencentContentModerationResponseException({
    required super.message,
    this.details,
    super.requestId,
    super.code = 'INVALID_RESPONSE',
  });

  @override
  String toString() {
    final detailText = details == null ? '' : '\nDetails: $details';
    return 'TencentContentModerationResponseException: $message$detailText';
  }
}
