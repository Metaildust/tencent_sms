/// Tencent Cloud SMS exception base class.
class TencentSmsException implements Exception {
  final String message;
  final String? code;

  const TencentSmsException({
    required this.message,
    this.code,
  });

  @override
  String toString() =>
      'TencentSmsException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Configuration error exception.
class TencentSmsConfigException extends TencentSmsException {
  const TencentSmsConfigException({required super.message})
      : super(code: 'CONFIG_ERROR');
}

/// SMS send failure exception.
class TencentSmsSendException extends TencentSmsException {
  const TencentSmsSendException({
    required super.message,
    super.code,
  });
}

/// HTTP request failure exception.
class TencentSmsHttpException extends TencentSmsException {
  final int statusCode;

  const TencentSmsHttpException({
    required this.statusCode,
    required super.message,
  }) : super(code: 'HTTP_ERROR');

  @override
  String toString() => 'TencentSmsHttpException: HTTP $statusCode - $message';
}
