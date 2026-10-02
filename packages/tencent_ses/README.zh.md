# tencent_ses

[![pub package](https://img.shields.io/pub/v/tencent_ses.svg)](https://pub.dev/packages/tencent_ses)

腾讯云 SES 的 Dart/Flutter SDK。

## 功能特性

- 基于 `SendEmail`（`2020-10-02`）发送模板邮件
- 通过 `tencent_cloud_api` 复用 TC3-HMAC-SHA256 签名
- 提供注册验证码与重置密码验证码邮件发送辅助方法
- 统一异常与响应模型

## 安装

```yaml
dependencies:
  tencent_ses: ^0.1.0
```

## 快速开始

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
    print('发送成功: ${response.messageId}');
  } finally {
    client.close();
  }
}
```

## 通用模板发送

```dart
await client.sendTemplateEmail(
  destination: ['user@example.com'],
  subject: '您的验证码',
  templateId: 100001,
  templateData: {
    'code': '123456',
    'requestId': 'request-id-1',
  },
);
```

## 配置说明

- `fromEmailAddress` 需为已认证发信地址。
- `templateIdRegister` 与 `templateIdResetPassword` 需为审核通过模板 ID。
- 默认 `triggerType = 1`（触发类邮件）。

## 许可证

MIT License
