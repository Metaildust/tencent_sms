# tencent_sms_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_sms_serverpod.svg)](https://pub.dev/packages/tencent_sms_serverpod)

Serverpod integration for Tencent Cloud SMS.

[中文文档](README.zh.md)

## Features

- **Config Integration** - Read credentials from `passwords.yaml`, pass other config directly
- **Callback Helper** - Provides callback helper class for `serverpod_auth_sms` integration
- **Full Export** - Re-exports all functionality from `tencent_sms` package

## Installation

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.2
```

## Configuration

### passwords.yaml (credentials only)

```yaml
shared:
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
```

### Code (non-sensitive config)

```dart
final config = TencentSmsConfigServerpod.fromServerpod(
  pod,
  appConfig: TencentSmsAppConfig(
    smsSdkAppId: '1400000000',
    signName: 'YourSignName',
    region: 'ap-guangzhou',
    templateCsvPath: 'config/sms/templates.csv',
    verificationTemplateNameLogin: 'Login',
    verificationTemplateNameRegister: 'Register',
    verificationTemplateNameResetPassword: 'ResetPassword',
  ),
);
```

## Quick Start

### Basic Usage

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

class MyEndpoint extends Endpoint {
  Future<void> sendCode(Session session, String phone) async {
    final config = TencentSmsConfigServerpod.fromSession(
      session,
      appConfig: TencentSmsAppConfig(
        smsSdkAppId: '1400000000',
        signName: 'YourSignName',
      ),
    );
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

  final smsConfig = TencentSmsConfigServerpod.fromServerpod(
    pod,
    appConfig: TencentSmsAppConfig(
      smsSdkAppId: '1400000000',
      signName: 'YourSignName',
      templateCsvPath: 'config/sms/templates.csv',
      verificationTemplateNameLogin: 'Login',
      verificationTemplateNameRegister: 'Register',
      verificationTemplateNameResetPassword: 'ResetPassword',
    ),
  );
  final smsClient = TencentSmsClient(smsConfig);
  final smsHelper = SmsAuthCallbackHelper(smsClient);

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

### TencentSmsAppConfig

Non-sensitive configuration:

```dart
TencentSmsAppConfig(
  smsSdkAppId: '1400000000',           // Required
  signName: 'YourSignName',             // Required
  region: 'ap-guangzhou',               // Optional, default: ap-guangzhou
  verificationTemplateId: '123456',     // Optional
  templateCsvPath: 'config/sms/templates.csv', // Optional
  verificationTemplateNameLogin: 'Login',       // Optional
  verificationTemplateNameRegister: 'Register', // Optional
  verificationTemplateNameResetPassword: 'Reset', // Optional
)
```

### TencentSmsPasswordKeys

Customize credential keys in passwords.yaml:

```dart
TencentSmsPasswordKeys(
  secretId: 'myCustomSecretIdKey',   // Default: tencentSmsSecretId
  secretKey: 'myCustomSecretKeyKey', // Default: tencentSmsSecretKey
)
```

### SmsAuthCallbackHelper

Create SMS send callbacks for `serverpod_auth_sms`:

```dart
final helper = SmsAuthCallbackHelper(smsClient);

helper.sendForRegistration   // Registration verification
helper.sendForLogin          // Login verification
helper.sendForBind           // Binding verification
helper.sendForResetPassword  // Password reset verification
```

## Troubleshooting

### Tencent Cloud Rate Limits

| Error Code | Description | Solution |
|------------|-------------|----------|
| `LimitExceeded.PhoneNumberOneHourLimit` | Hourly limit exceeded | Wait or adjust limit in console |
| `LimitExceeded.PhoneNumberDailyLimit` | Daily limit exceeded | Same as above |
| `LimitExceeded.PhoneNumberThirtySecondLimit` | 30-second rate limit | Add cooldown timer in frontend |

### Signature and Template Approval

Before sending SMS, ensure:
1. SMS signature is approved in Tencent Cloud console
2. SMS template is approved in Tencent Cloud console
3. `signName` config value exactly matches the approved signature

## Related Packages

- [tencent_sms](https://pub.dev/packages/tencent_sms) - Tencent Cloud SMS core package
- [serverpod_auth_sms](https://pub.dev/packages/serverpod_auth_sms) - Serverpod SMS authentication

## License

MIT License
