# tencent_sms

[![pub package](https://img.shields.io/pub/v/tencent_sms.svg)](https://pub.dev/packages/tencent_sms)

腾讯云短信 SDK for Dart/Flutter - 支持验证码发送、批量发送、CSV模板映射、多场景模板。

[English](README.md)

## 功能特性

- **验证码发送** - 单条验证码短信发送
- **批量发送** - 支持多手机号批量发送
- **多场景模板** - 登录/注册/重置密码使用不同模板
- **CSV 模板映射** - 支持从腾讯云控制台导出的 CSV 文件读取模板 ID
- **TC3 签名** - 使用最新的腾讯云 API 签名算法
- **纯 Dart 实现** - 不依赖任何框架，支持 Flutter 和服务端

## 安装

```yaml
dependencies:
  tencent_sms: ^0.1.0
```

## 快速开始

```dart
import 'package:tencent_sms/tencent_sms.dart';

void main() async {
  final config = TencentSmsConfig(
    secretId: 'your-secret-id',
    secretKey: 'your-secret-key',
    smsSdkAppId: '1400000000',
    signName: '你的签名',
    region: 'ap-guangzhou',
    verificationTemplateId: '123456', // 验证码模板 ID
  );

  final client = TencentSmsClient(config);

  try {
    final response = await client.sendVerificationCode(
      phoneNumber: '13800138000', // 自动转为 +8613800138000
      verificationCode: '123456',
    );
    print('发送成功: ${response.requestId}');
  } catch (e) {
    print('发送失败: $e');
  } finally {
    client.close();
  }
}
```

## 使用方法

### 发送验证码

```dart
// 单条验证码（使用默认模板）
await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

// 指定模板 ID
await client.sendVerificationCode(
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
  templateId: '789012',
);
```

### 多场景模板

```dart
final config = TencentSmsConfig(
  // ...基本配置
  templateCsvPath: 'config/sms/templates.csv',
  verificationTemplateNameLogin: '登录验证码',
  verificationTemplateNameRegister: '注册验证码',
  verificationTemplateNameResetPassword: '重置密码验证码',
);

final client = TencentSmsClient(config);

// 登录场景
await client.sendVerificationCodeForScene(
  scene: SmsVerificationScene.login,
  phoneNumber: '+8613800138000',
  verificationCode: '123456',
);

// 注册场景
await client.sendVerificationCodeForScene(
  scene: SmsVerificationScene.register,
  phoneNumber: '+8613800138000',
  verificationCode: '654321',
);
```

### 批量发送

```dart
final response = await client.sendSms(
  phoneNumbers: ['+8613800138000', '+8613800138001'],
  templateId: '123456',
  templateParams: ['订单已发货', '顺丰快递', 'SF123456'],
);

for (final status in response.statuses) {
  print('${status.phoneNumber}: ${status.isOk ? '成功' : status.message}');
}
```

### CSV 模板映射

从腾讯云短信控制台导出模板列表 CSV 文件，放置在项目中：

```csv
模板ID,模板名称,模板内容,审核状态,创建时间
123456,登录验证码,您的登录验证码是{1}...,已通过,2024-01-01
123457,注册验证码,您的注册验证码是{1}...,已通过,2024-01-01
```

然后配置：

```dart
final config = TencentSmsConfig(
  // ...基本配置
  templateCsvPath: 'config/sms/templates.csv',
  verificationTemplateNameLogin: '登录验证码',
);
```

## 配置说明

| 参数 | 必填 | 说明 |
|------|------|------|
| `secretId` | 是 | 腾讯云 SecretId |
| `secretKey` | 是 | 腾讯云 SecretKey |
| `smsSdkAppId` | 是 | 短信应用 SDK AppID |
| `signName` | 是 | 短信签名内容 |
| `region` | 否 | 地域，默认 `ap-guangzhou` |
| `verificationTemplateId` | 否 | 验证码模板 ID（优先级最高）|
| `templateCsvPath` | 否 | 模板 CSV 文件路径 |
| `verificationTemplateNameLogin` | 否 | 登录模板名称 |
| `verificationTemplateNameRegister` | 否 | 注册模板名称 |
| `verificationTemplateNameResetPassword` | 否 | 重置密码模板名称 |

## 手机号格式

支持以下格式，自动转换为 E.164 格式：

- `+8613800138000` - E.164 格式（原样使用）
- `13800138000` - 国内 11 位手机号（自动添加 +86）
- `008613800138000` - 国际格式（自动转换）

## 异常处理

```dart
try {
  await client.sendVerificationCode(...);
} on TencentSmsConfigException catch (e) {
  // 配置错误（如模板未配置）
  print('配置错误: ${e.message}');
} on TencentSmsSendException catch (e) {
  // 发送失败（如余额不足、频率限制）
  print('发送失败: ${e.message} (${e.code})');
} on TencentSmsHttpException catch (e) {
  // HTTP 请求失败
  print('网络错误: HTTP ${e.statusCode}');
}
```

## Serverpod 集成

如果你使用 Serverpod，推荐配合 `tencent_sms_serverpod` 包使用，支持从 `passwords.yaml` 读取配置：

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.2
```

详见 [tencent_sms_serverpod](https://pub.dev/packages/tencent_sms_serverpod)。

## 相关资源

- [腾讯云短信文档](https://cloud.tencent.com/document/product/382)
- [SendSms API 文档](https://cloud.tencent.com/document/product/382/55981)

## 许可证

MIT License
