# tencent_sms

[![pub package](https://img.shields.io/pub/v/tencent_sms.svg)](https://pub.dev/packages/tencent_sms)

Tencent Cloud SMS SDK for Dart/Flutter - Supporting verification code sending, batch sending, CSV template mapping, and multi-scene templates.

[中文文档](README.zh.md)

## Features

- **Verification Code Sending** - Single verification code SMS sending
- **Batch Sending** - Support batch sending to multiple phone numbers
- **Multi-scene Templates** - Different templates for login/registration/password reset
- **CSV Template Mapping** - Support reading template IDs from CSV exported from Tencent Cloud console
- **TC3 Signature** - Using the latest Tencent Cloud API signature algorithm
- **Pure Dart** - No framework dependency, supports Flutter and server-side

## Installation

```yaml
dependencies:
  tencent_sms: ^0.1.0
```

## Quick Start

```dart
import 'package:tencent_sms/tencent_sms.dart';

void main() async {
  final config = TencentSmsConfig(
    secretId: 'your-secret-id',
    secretKey: 'your-secret-key',
    smsSdkAppId: '1400000000',
    signName: 'YourSignName',
    region: 'ap-guangzhou',
    verificationTemplateId: '123456',
  );

  final client = TencentSmsClient(config);

  try {
    final response = await client.sendVerificationCode(
      phoneNumber: '+8613800138000',
      verificationCode: '123456',
    );
    print('Sent successfully: ${response.requestId}');
  } catch (e) {
    print('Failed to send: $e');
  } finally {
    client.close();
  }
}
```

## Usage

### Send Verification Code

```dart
// Single verification code (using default template)
await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

// Specify template ID
await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
  templateId: '789012',
);
```

### Multi-scene Templates

```dart
final config = TencentSmsConfig(
  // ...basic config
  templateCsvPath: 'config/sms/templates.csv',
  verificationTemplateNameLogin: 'Login Verification',
  verificationTemplateNameRegister: 'Registration Verification',
  verificationTemplateNameResetPassword: 'Password Reset Verification',
);

final client = TencentSmsClient(config);

// Login scene
await client.sendVerificationCodeForScene(
  scene: SmsVerificationScene.login,
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

// Registration scene
await client.sendVerificationCodeForScene(
  scene: SmsVerificationScene.register,
  phoneNumber: '+8613800138000',
  verificationCode: '654321',
);
```

### Batch Sending

```dart
final response = await client.sendSms(
  phoneNumbers: ['+8613800138000', '+8613800138001'],
  templateId: '123456',
  templateParams: ['Order shipped', 'SF Express', 'SF123456'],
);

for (final status in response.statuses) {
  print('${status.phoneNumber}: ${status.isOk ? 'Success' : status.message}');
}
```

## Configuration

| Parameter | Required | Description |
|-----------|----------|-------------|
| `secretId` | Yes | Tencent Cloud SecretId |
| `secretKey` | Yes | Tencent Cloud SecretKey |
| `smsSdkAppId` | Yes | SMS SDK AppID |
| `signName` | Yes | SMS signature |
| `region` | No | Region, default `ap-guangzhou` |
| `verificationTemplateId` | No | Verification template ID (highest priority) |
| `templateCsvPath` | No | Template CSV file path |
| `verificationTemplateNameLogin` | No | Login template name |
| `verificationTemplateNameRegister` | No | Registration template name |
| `verificationTemplateNameResetPassword` | No | Password reset template name |

## Phone Number Format

Supports the following formats, automatically converted to E.164 format:

- `+8613800138000` - E.164 format (used as-is)
- `13800138000` - 11-digit Chinese mobile number (auto-prefixed with +86)
- `008613800138000` - International format (auto-converted)

## Exception Handling

```dart
try {
  await client.sendVerificationCode(...);
} on TencentSmsConfigException catch (e) {
  // Configuration error
  print('Config error: ${e.message}');
} on TencentSmsSendException catch (e) {
  // Send failure
  print('Send failed: ${e.message} (${e.code})');
} on TencentSmsHttpException catch (e) {
  // HTTP request failure
  print('Network error: HTTP ${e.statusCode}');
}
```

## Serverpod Integration

If you use Serverpod, we recommend using `tencent_sms_serverpod` package for reading config from `passwords.yaml`:

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.2
```

See [tencent_sms_serverpod](https://pub.dev/packages/tencent_sms_serverpod) for details.

## Resources

- [Tencent Cloud SMS Documentation](https://cloud.tencent.com/document/product/382)
- [SendSms API Documentation](https://cloud.tencent.com/document/product/382/55981)

## License

MIT License
