# tencent_sms_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_sms_serverpod.svg)](https://pub.dev/packages/tencent_sms_serverpod)

Serverpod integration extension for Tencent Cloud SMS - Read configuration from passwords.yaml.

[中文文档](README.zh.md)

## Features

- **Config Integration** - Read Tencent Cloud SMS config from Serverpod's `passwords.yaml`
- **Callback Helper** - Provides callback helper class for `serverpod_auth_sms` integration
- **Full Export** - Re-exports all functionality from `tencent_sms` package

## Installation

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.1
```

## Configuration

Add to `config/passwords.yaml`:

```yaml
shared:
  # Required
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
  tencentSmsSdkAppId: '1400000000'
  tencentSmsSignName: 'YourSignName'

  # Optional
  tencentSmsRegion: 'ap-guangzhou'  # Default ap-guangzhou
  tencentSmsVerificationTemplateId: '123456'

  # CSV template mapping (optional)
  tencentSmsTemplateCsvPath: 'config/sms/templates.csv'
  tencentSmsVerificationTemplateNameLogin: 'Login Verification'
  tencentSmsVerificationTemplateNameRegister: 'Registration Verification'
  tencentSmsVerificationTemplateNameResetPassword: 'Password Reset Verification'
```

## Quick Start

### Basic Usage

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

// In an Endpoint
class MyEndpoint extends Endpoint {
  Future<void> sendCode(Session session, String phone) async {
    final config = TencentSmsConfigServerpod.fromSession(session);
    final client = TencentSmsClient(config);

    await client.sendVerificationCode(
      phoneNumber: phone,
      verificationCode: '123456',
    );

    client.close();
  }
}
```

### Integration with serverpod_auth_sms

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Create Tencent Cloud SMS client
  final smsConfig = TencentSmsConfigServerpod.fromServerpod(pod);
  final smsClient = TencentSmsClient(smsConfig);

  // Create callback helper
  final smsHelper = SmsAuthCallbackHelper(smsClient);

  // Configure phone ID store
  final phoneIdStore = PhoneIdCryptoStore.fromPasswords(pod);

  pod.initializeAuthServices(
    tokenManagerBuilders: [JwtConfigFromPasswords()],
    identityProviderBuilders: [
      SmsIdpConfigFromPasswords(
        phoneIdStore: phoneIdStore,
        sendRegistrationVerificationCode: smsHelper.sendForRegistration,
        sendLoginVerificationCode: smsHelper.sendForLogin,
        sendBindVerificationCode: smsHelper.sendForBind,
      ),
    ],
  );

  await pod.start();
}
```

## API Reference

### TencentSmsConfigServerpod

Create Tencent Cloud SMS config from Serverpod configuration:

```dart
// From Session (use in Endpoints)
final config = TencentSmsConfigServerpod.fromSession(session);

// From Serverpod instance (use during initialization)
final config = TencentSmsConfigServerpod.fromServerpod(pod);
```

### SmsAuthCallbackHelper

Create SMS send callbacks for `serverpod_auth_sms`:

```dart
final helper = SmsAuthCallbackHelper(smsClient);

// Available callback methods
helper.sendForRegistration   // Registration verification
helper.sendForLogin          // Login verification
helper.sendForBind           // Binding verification
helper.sendForResetPassword  // Password reset verification
```

## Troubleshooting

### Tencent Cloud Rate Limits

Tencent Cloud has SMS sending rate limits. Common error codes:

| Error Code | Description | Solution |
|------------|-------------|----------|
| `LimitExceeded.PhoneNumberOneHourLimit` | Hourly limit exceeded for single phone | Wait or adjust limit in console |
| `LimitExceeded.PhoneNumberDailyLimit` | Daily limit exceeded for single phone | Same as above |
| `LimitExceeded.PhoneNumberThirtySecondLimit` | 30-second rate limit exceeded | Add cooldown timer in frontend |

We recommend implementing a cooldown countdown (e.g., 60 seconds) in your frontend to prevent users from triggering rate limits.

### Signature and Template Approval

Before sending SMS, ensure:
1. SMS signature is approved in Tencent Cloud console
2. SMS template is approved in Tencent Cloud console
3. `tencentSmsSignName` config value exactly matches the approved signature

## Related Packages

- [tencent_sms](https://pub.dev/packages/tencent_sms) - Tencent Cloud SMS core package
- [serverpod_auth_sms](https://pub.dev/packages/serverpod_auth_sms) - Serverpod SMS authentication

## License

MIT License
