# tencent_ses

[![pub package](https://img.shields.io/pub/v/tencent_ses.svg)](https://pub.dev/packages/tencent_ses)

Tencent Cloud SES SDK for Dart/Flutter.

## Features

- Template email sending via `SendEmail` API (`2020-10-02`)
- TC3-HMAC-SHA256 signing via `tencent_cloud_api`
- Verification helpers for registration and password reset emails
- Unified exception and response models

## Installation

```yaml
dependencies:
  tencent_ses: ^0.1.0
```

## Quick Start

```dart
import 'package:tencent_ses/tencent_ses.dart';

void main() async {
  final config = TencentSesConfig(
    secretId: 'your-secret-id',
    secretKey: 'your-secret-key',
    region: 'ap-guangzhou',
    fromEmailAddress: 'QCLOUDTEAM <noreply@example.com>',
    templateIdRegister: 100001,
    templateIdResetPassword: 100002,
  );

  final client = TencentSesClient(config);

  try {
    final response = await client.sendRegistrationVerificationCode(
      email: 'user@example.com',
      verificationCode: '123456',
      requestId: 'request-id-1',
    );
    print('Sent: ${response.messageId}');
  } finally {
    client.close();
  }
}
```

## Generic Template Send

```dart
await client.sendTemplateEmail(
  destination: ['user@example.com'],
  subject: 'Your verification code',
  templateId: 100001,
  templateData: {
    'code': '123456',
    'requestId': 'request-id-1',
  },
);
```

## Configuration Notes

- `fromEmailAddress` must be a verified sender in Tencent SES.
- `templateIdRegister` and `templateIdResetPassword` should be approved template IDs.
- `triggerType` default is `1` (triggered mail).

## API Reference

### `TencentSesConfig`

Core configuration for SES client:

- `secretId`, `secretKey`, `region`, `token`
- `fromEmailAddress`, `replyToAddresses`
- `subjectRegister`, `subjectResetPassword`
- `templateIdRegister`, `templateIdResetPassword`
- `templateDataCodeKey`, `templateDataRequestIdKey`

### `TencentSesClient`

- `sendTemplateEmail(...)`
- `sendRegistrationVerificationCode(...)`
- `sendPasswordResetVerificationCode(...)`

## License

MIT License
