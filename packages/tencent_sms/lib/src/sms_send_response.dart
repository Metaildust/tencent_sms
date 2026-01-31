/// 短信发送错误信息
class SmsSendError {
  final String code;
  final String message;

  const SmsSendError({
    required this.code,
    required this.message,
  });

  factory SmsSendError.fromJson(Map<String, dynamic> json) {
    return SmsSendError(
      code: json['Code']?.toString() ?? 'UnknownError',
      message: json['Message']?.toString() ?? 'Unknown error',
    );
  }

  @override
  String toString() => 'SmsSendError($code: $message)';
}

/// 单条短信发送状态
class SmsSendStatus {
  /// 发送流水号
  final String serialNo;

  /// 手机号码（E.164 格式）
  final String phoneNumber;

  /// 计费条数
  final int fee;

  /// 用户自定义的 Session 内容
  final String sessionContext;

  /// 短信请求错误码（Ok 表示成功）
  final String code;

  /// 短信请求错误描述
  final String message;

  /// 国家码或地区码（如 CN）
  final String isoCode;

  const SmsSendStatus({
    required this.serialNo,
    required this.phoneNumber,
    required this.fee,
    required this.sessionContext,
    required this.code,
    required this.message,
    required this.isoCode,
  });

  /// 是否发送成功
  bool get isOk => code == 'Ok';

  factory SmsSendStatus.fromJson(Map<String, dynamic> json) {
    return SmsSendStatus(
      serialNo: json['SerialNo']?.toString() ?? '',
      phoneNumber: json['PhoneNumber']?.toString() ?? '',
      fee: json['Fee'] is int
          ? json['Fee'] as int
          : int.tryParse(json['Fee']?.toString() ?? '0') ?? 0,
      sessionContext: json['SessionContext']?.toString() ?? '',
      code: json['Code']?.toString() ?? 'UnknownError',
      message: json['Message']?.toString() ?? 'Unknown message',
      isoCode: json['IsoCode']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'SmsSendStatus($phoneNumber: $code)';
}

/// 短信发送响应
class SmsSendResponse {
  /// 各手机号的发送状态列表
  final List<SmsSendStatus> statuses;

  /// 腾讯云请求 ID
  final String requestId;

  /// 错误信息（如果有）
  final SmsSendError? error;

  const SmsSendResponse({
    required this.statuses,
    required this.requestId,
    this.error,
  });

  /// 是否全部发送成功
  bool get isOk => error == null && statuses.every((s) => s.isOk);

  factory SmsSendResponse.fromJson(Map<String, dynamic> json) {
    final response = json['Response'] as Map<String, dynamic>? ?? {};
    final errorJson = response['Error'] as Map<String, dynamic>?;
    final statusList = (response['SendStatusSet'] as List<dynamic>? ?? [])
        .map((e) => SmsSendStatus.fromJson(e as Map<String, dynamic>))
        .toList();

    return SmsSendResponse(
      statuses: statusList,
      requestId: response['RequestId']?.toString() ?? '',
      error: errorJson == null ? null : SmsSendError.fromJson(errorJson),
    );
  }

  @override
  String toString() =>
      'SmsSendResponse(requestId: $requestId, isOk: $isOk, statuses: ${statuses.length})';
}
