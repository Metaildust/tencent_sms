/// Base exception for Tencent Cloud API client failures.
class TencentCloudApiException implements Exception {
  final String message;
  final String? code;

  const TencentCloudApiException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'TencentCloudApiException: '
      '$message${code != null ? ' (code: $code)' : ''}';
}

/// HTTP layer error.
class TencentCloudApiHttpException extends TencentCloudApiException {
  final int statusCode;
  final String? responseBody;

  const TencentCloudApiHttpException({
    required this.statusCode,
    this.responseBody,
    required super.message,
    super.code = 'HTTP_ERROR',
  });

  @override
  String toString() =>
      'TencentCloudApiHttpException: HTTP $statusCode - $message';
}

/// Response parsing/shape error.
class TencentCloudApiResponseException extends TencentCloudApiException {
  final String? details;

  const TencentCloudApiResponseException({
    required super.message,
    super.code = 'INVALID_RESPONSE',
    this.details,
  });

  @override
  String toString() {
    final detailText = details == null ? '' : '\nDetails: $details';
    return 'TencentCloudApiResponseException: $message$detailText';
  }
}

/// Invalid request setup before sending.
class TencentCloudApiRequestException extends TencentCloudApiException {
  const TencentCloudApiRequestException({
    required super.message,
    super.code = 'INVALID_REQUEST',
  });
}
