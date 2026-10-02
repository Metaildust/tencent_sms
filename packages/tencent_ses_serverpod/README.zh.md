# tencent_ses_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_ses_serverpod.svg)](https://pub.dev/packages/tencent_ses_serverpod)

腾讯云 SES 的 Serverpod 集成包。

[English](README.md)

## 功能特性

- 从 `passwords.yaml` 读取腾讯云 SES 凭据
- 非敏感配置放在代码中，便于按业务场景管理
- 重新导出 `tencent_ses` 的全部能力

## 安装

```yaml
dependencies:
  tencent_ses_serverpod: ^0.1.0
```

## 配置

### `passwords.yaml`（仅凭据）

```yaml
shared:
  tencentSesSecretId: 'your-secret-id'
  tencentSesSecretKey: 'your-secret-key'
```

### 代码（非敏感配置）

```dart
import 'package:tencent_ses_serverpod/tencent_ses_serverpod.dart';

final sesConfig = TencentSesConfigServerpod.fromServerpod(
  pod,
  appConfig: const TencentSesAppConfig(
    region: 'ap-guangzhou',
    fromEmailAddress: 'QCLOUDTEAM <noreply@example.com>',
    templateIdRegister: 100001,
    templateIdResetPassword: 100002,
    subjectRegister: '邮箱验证码',
    subjectResetPassword: '重置密码验证码',
  ),
);

final sesClient = TencentSesClient(sesConfig);
```

## API 说明

### `TencentSesPasswordKeys`

用于自定义 `passwords.yaml` 中的键名：

```dart
const keys = TencentSesPasswordKeys(
  secretId: 'mySesSecretId',
  secretKey: 'mySesSecretKey',
);
```

### `TencentSesAppConfig`

包含以下非敏感配置：

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

## 许可证

MIT License
