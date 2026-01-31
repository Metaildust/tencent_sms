# tencent_sms_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_sms_serverpod.svg)](https://pub.dev/packages/tencent_sms_serverpod)

腾讯云短信的 Serverpod 集成扩展 - 支持从 passwords.yaml 读取配置。

[English](README.md)

## 功能特性

- **配置集成** - 从 Serverpod 的 `passwords.yaml` 读取腾讯云短信配置
- **回调辅助** - 提供与 `serverpod_auth_sms` 集成的回调辅助类
- **完整导出** - 重新导出 `tencent_sms` 包的所有功能

## 安装

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.0
```

## 配置

在 `config/passwords.yaml` 中添加：

```yaml
shared:
  # 必填项
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
  tencentSmsSdkAppId: '1400000000'
  tencentSmsSignName: '你的签名'

  # 可选项
  tencentSmsRegion: 'ap-guangzhou'  # 默认 ap-guangzhou
  tencentSmsVerificationTemplateId: '123456'  # 验证码模板 ID

  # CSV 模板映射（可选）
  tencentSmsTemplateCsvPath: 'config/sms/templates.csv'
  tencentSmsVerificationTemplateNameLogin: '登录验证码'
  tencentSmsVerificationTemplateNameRegister: '注册验证码'
  tencentSmsVerificationTemplateNameResetPassword: '重置密码验证码'
```

## 快速开始

### 基本使用

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

// 在 Endpoint 中使用
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

### 与 serverpod_auth_sms 集成

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  // 创建腾讯云短信客户端
  final smsConfig = TencentSmsConfigServerpod.fromServerpod(pod);
  final smsClient = TencentSmsClient(smsConfig);

  // 创建回调辅助类
  final smsHelper = SmsAuthCallbackHelper(smsClient);

  // 配置手机号存储
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

## API 参考

### TencentSmsConfigServerpod

从 Serverpod 配置创建腾讯云短信配置：

```dart
// 从 Session 创建（在 Endpoint 中使用）
final config = TencentSmsConfigServerpod.fromSession(session);

// 从 Serverpod 实例创建（在初始化阶段使用）
final config = TencentSmsConfigServerpod.fromServerpod(pod);
```

### SmsAuthCallbackHelper

为 `serverpod_auth_sms` 创建短信发送回调：

```dart
final helper = SmsAuthCallbackHelper(smsClient);

// 可用的回调方法
helper.sendForRegistration   // 注册验证码
helper.sendForLogin          // 登录验证码
helper.sendForBind           // 绑定验证码
helper.sendForResetPassword  // 重置密码验证码
```

## 常见问题

### 腾讯云频率限制错误

腾讯云对短信发送有频率限制，常见错误码：

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| `LimitExceeded.PhoneNumberOneHourLimit` | 单手机号1小时内发送数量超限 | 等待或在控制台调整限制 |
| `LimitExceeded.PhoneNumberDailyLimit` | 单手机号日发送数量超限 | 同上 |
| `LimitExceeded.PhoneNumberThirtySecondLimit` | 30秒内发送频率超限 | 前端添加冷却时间 |

建议在前端实现发送冷却倒计时（如60秒），避免用户频繁点击触发限制。

### 签名和模板审核

发送短信前需确保：
1. 短信签名已在腾讯云控制台审核通过
2. 短信模板已在腾讯云控制台审核通过
3. `tencentSmsSignName` 配置值与审核通过的签名完全一致

## 相关包

- [tencent_sms](https://pub.dev/packages/tencent_sms) - 腾讯云短信核心包
- [serverpod_auth_sms](https://pub.dev/packages/serverpod_auth_sms) - Serverpod 短信认证

## 许可证

MIT License
