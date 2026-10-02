# tencent_ses_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_ses_serverpod.svg)](https://pub.dev/packages/tencent_ses_serverpod)

Serverpod integration for Tencent Cloud SES.

[中文文档](README.zh.md)

## Features

- Load SES credentials from `passwords.yaml`
- Keep non-sensitive settings in code
- Re-export all APIs from `tencent_ses`

## Installation

```yaml
dependencies:
  tencent_ses_serverpod: ^0.1.0
```

## Configuration

### `passwords.yaml` (credentials only)

```yaml
shared:
  tencentSesSecretId: 'your-secret-id'
  tencentSesSecretKey: 'your-secret-key'
```

### Code (non-sensitive values)

```dart
import 'package:tencent_ses_serverpod/tencent_ses_serverpod.dart';

final sesConfig = TencentSesConfigServerpod.fromServerpod(
  pod,
  appConfig: const TencentSesAppConfig(
    region: 'ap-guangzhou',
    fromEmailAddress: 'QCLOUDTEAM <noreply@example.com>',
    templateIdRegister: 100001,
    templateIdResetPassword: 100002,
    subjectRegister: 'Your verification code',
    subjectResetPassword: 'Password reset code',
  ),
);

final sesClient = TencentSesClient(sesConfig);
```

## API Reference

### `TencentSesPasswordKeys`

Customize credential key names in `passwords.yaml`:

```dart
const keys = TencentSesPasswordKeys(
  secretId: 'mySesSecretId',
  secretKey: 'mySesSecretKey',
);
```

### `TencentSesAppConfig`

Non-sensitive settings:

- `region`
- `fromEmailAddress`
- `replyToAddresses`
- `subjectRegister`
- `subjectResetPassword`
- `templateIdRegister`
- `templateIdResetPassword`
- `templateDataCodeKey`
- `templateDataRequestIdKey`
- `defaultTriggerType`

## License

MIT License
