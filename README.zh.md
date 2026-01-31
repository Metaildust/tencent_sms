# Tencent SMS

[![Pub Version](https://img.shields.io/pub/v/tencent_sms)](https://pub.dev/packages/tencent_sms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

腾讯云短信 SDK for Dart/Flutter - 支持验证码发送、批量发送、CSV模板映射、多场景模板。

[English](README.md)

## 功能特性

- **验证码发送** - 快速发送验证码短信
- **批量发送** - 支持批量发送短信
- **CSV 模板映射** - 通过 CSV 文件管理模板 ID
- **多场景模板** - 登录、注册、重置密码等场景模板
- **TC3-HMAC-SHA256 签名** - 腾讯云 API v3 签名算法

## 包结构

| 包名 | 说明 |
|------|------|
| [tencent_sms](packages/tencent_sms/) | 核心包，纯 Dart 实现 |
| [tencent_sms_serverpod](packages/tencent_sms_serverpod/) | Serverpod 集成扩展 |

## 快速开始

### 纯 Dart/Flutter

```yaml
dependencies:
  tencent_sms: ^0.1.1
```

```dart
import 'package:tencent_sms/tencent_sms.dart';

final client = TencentSmsClient(TencentSmsConfig(
  secretId: 'your-secret-id',
  secretKey: 'your-secret-key',
  sdkAppId: '1400000000',
  signName: '你的签名',
));

await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

client.close();
```

### Serverpod 集成

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.1
```

配置 `config/passwords.yaml`:

```yaml
shared:
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
  tencentSmsSdkAppId: '1400000000'
  tencentSmsSignName: '你的签名'
```

使用：

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

final config = TencentSmsConfigServerpod.fromServerpod(pod);
final client = TencentSmsClient(config);
```

## 与 serverpod_auth_sms 集成

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

## 文档

- [核心包文档](packages/tencent_sms/README.md)
- [Serverpod 集成文档](packages/tencent_sms_serverpod/README.md)

## 许可证

MIT License
