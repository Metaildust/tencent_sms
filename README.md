# Tencent SMS

[![Pub Version](https://img.shields.io/pub/v/tencent_sms)](https://pub.dev/packages/tencent_sms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Tencent Cloud SMS SDK for Dart/Flutter - verification code sending, batch sending, CSV template mapping, multi-scenario templates.

[中文文档](README.zh.md)

## Features

- **Verification Code Sending** - Quick verification code SMS
- **Batch Sending** - Support batch SMS sending
- **CSV Template Mapping** - Manage template IDs via CSV files
- **Multi-scenario Templates** - Login, registration, password reset templates
- **TC3-HMAC-SHA256 Signature** - Tencent Cloud API v3 signature algorithm

## Package Structure

| Package | Description |
|---------|-------------|
| [tencent_sms](packages/tencent_sms/) | Core package, pure Dart |
| [tencent_sms_serverpod](packages/tencent_sms_serverpod/) | Serverpod integration |

## Quick Start

### Pure Dart/Flutter

```yaml
dependencies:
  tencent_sms: ^0.1.0
```

```dart
import 'package:tencent_sms/tencent_sms.dart';

final client = TencentSmsClient(TencentSmsConfig(
  secretId: 'your-secret-id',
  secretKey: 'your-secret-key',
  sdkAppId: '1400000000',
  signName: 'YourSignName',
));

await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

client.close();
```

### Serverpod Integration

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.0
```

Configure `config/passwords.yaml`:

```yaml
shared:
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
  tencentSmsSdkAppId: '1400000000'
  tencentSmsSignName: 'YourSignName'
```

Usage:

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

final config = TencentSmsConfigServerpod.fromServerpod(pod);
final client = TencentSmsClient(config);
```

## Integration with serverpod_auth_sms

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';

final smsHelper = SmsAuthCallbackHelper(smsClient);

SmsIdpConfigFromPasswords(
  sendRegistrationVerificationCode: smsHelper.sendForRegistration,
  sendLoginVerificationCode: smsHelper.sendForLogin,
  sendBindVerificationCode: smsHelper.sendForBind,
)
```

## Documentation

- [Core Package Docs](packages/tencent_sms/README.md)
- [Serverpod Integration Docs](packages/tencent_sms_serverpod/README.md)

## License

MIT License
