/// Tencent Cloud SES configuration.
class TencentSesConfig {
  /// Tencent Cloud SecretId.
  final String secretId;

  /// Tencent Cloud SecretKey.
  final String secretKey;

  /// Region for SES API requests.
  final String region;

  /// Optional temporary credential token.
  final String? token;

  /// Sender email address.
  ///
  /// Supports format: `Alias <sender@example.com>`.
  final String fromEmailAddress;

  /// Optional reply-to address.
  final String? replyToAddresses;

  /// Email subject for registration verification.
  final String subjectRegister;

  /// Email subject for password reset verification.
  final String subjectResetPassword;

  /// Template ID used for registration verification.
  final int? templateIdRegister;

  /// Template ID used for password reset verification.
  final int? templateIdResetPassword;

  /// Key name for verification code in template data.
  final String templateDataCodeKey;

  /// Optional key name for request ID in template data.
  final String? templateDataRequestIdKey;

  /// Default trigger type for SES request.
  ///
  /// - `0`: non-triggered
  /// - `1`: triggered (recommended for verification code emails)
  final int defaultTriggerType;

  const TencentSesConfig({
    required this.secretId,
    required this.secretKey,
    required this.fromEmailAddress,
    this.region = 'ap-guangzhou',
    this.token,
    this.replyToAddresses,
    this.subjectRegister = '验证码',
    this.subjectResetPassword = '重置密码验证码',
    this.templateIdRegister,
    this.templateIdResetPassword,
    this.templateDataCodeKey = 'code',
    this.templateDataRequestIdKey = 'requestId',
    this.defaultTriggerType = 1,
  });

  /// Creates a modified copy of this config.
  TencentSesConfig copyWith({
    String? secretId,
    String? secretKey,
    String? region,
    String? token,
    String? fromEmailAddress,
    String? replyToAddresses,
    String? subjectRegister,
    String? subjectResetPassword,
    int? templateIdRegister,
    int? templateIdResetPassword,
    String? templateDataCodeKey,
    String? templateDataRequestIdKey,
    int? defaultTriggerType,
  }) {
    return TencentSesConfig(
      secretId: secretId ?? this.secretId,
      secretKey: secretKey ?? this.secretKey,
      fromEmailAddress: fromEmailAddress ?? this.fromEmailAddress,
      region: region ?? this.region,
      token: token ?? this.token,
      replyToAddresses: replyToAddresses ?? this.replyToAddresses,
      subjectRegister: subjectRegister ?? this.subjectRegister,
      subjectResetPassword: subjectResetPassword ?? this.subjectResetPassword,
      templateIdRegister: templateIdRegister ?? this.templateIdRegister,
      templateIdResetPassword:
          templateIdResetPassword ?? this.templateIdResetPassword,
      templateDataCodeKey: templateDataCodeKey ?? this.templateDataCodeKey,
      templateDataRequestIdKey:
          templateDataRequestIdKey ?? this.templateDataRequestIdKey,
      defaultTriggerType: defaultTriggerType ?? this.defaultTriggerType,
    );
  }
}
