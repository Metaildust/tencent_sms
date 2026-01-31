/// 腾讯云短信异常基类
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

/// 配置错误异常
class TencentSmsConfigException extends TencentSmsException {
  const TencentSmsConfigException({required super.message})
      : super(code: 'CONFIG_ERROR');
}

/// 短信发送失败异常
class TencentSmsSendException extends TencentSmsException {
  const TencentSmsSendException({
    required super.message,
    super.code,
  });
}

/// HTTP 请求失败异常
class TencentSmsHttpException extends TencentSmsException {
  final int statusCode;

  const TencentSmsHttpException({
    required this.statusCode,
    required super.message,
  }) : super(code: 'HTTP_ERROR');

  @override
  String toString() => 'TencentSmsHttpException: HTTP $statusCode - $message';
}
