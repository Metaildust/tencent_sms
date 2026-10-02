/// Base exception for Tencent SES failures.
class TencentSesException implements Exception {
  final String message;
  final String? code;

  const TencentSesException({required this.message, this.code});

  @override
  String toString() =>
      'TencentSesException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Configuration error.
class TencentSesConfigException extends TencentSesException {
  const TencentSesConfigException({required super.message})
    : super(code: 'CONFIG_ERROR');
}

/// Send failure from SES.
class TencentSesSendException extends TencentSesException {
  const TencentSesSendException({required super.message, super.code});
}

/// HTTP request failure.
class TencentSesHttpException extends TencentSesException {
  final int statusCode;

  const TencentSesHttpException({
    required this.statusCode,
    required super.message,
  }) : super(code: 'HTTP_ERROR');

  @override
  String toString() => 'TencentSesHttpException: HTTP $statusCode - $message';
}
