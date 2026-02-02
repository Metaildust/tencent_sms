# tencent_sms_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_sms_serverpod.svg)](https://pub.dev/packages/tencent_sms_serverpod)

腾讯云短信的 Serverpod 集成。

[English](README.md)

## 功能特性

- **配置集成** - 从 `passwords.yaml` 读取凭据，其他配置直接传入
- **回调辅助** - 提供与 `serverpod_auth_sms` 集成的回调辅助类
- **完整导出** - 重新导出 `tencent_sms` 包的所有功能

## 安装

```yaml
dependencies:
  tencent_sms_serverpod: ^0.1.2
```

## 配置

### passwords.yaml（仅凭据）

```yaml
shared:
  tencentSmsSecretId: 'your-secret-id'
  tencentSmsSecretKey: 'your-secret-key'
```

### 代码（非敏感配置）

```dart
final config = TencentSmsConfigServerpod.fromServerpod(
  pod,
  appConfig: TencentSmsAppConfig(
    smsSdkAppId: '1400000000',
    signName: '你的签名',
    region: 'ap-guangzhou',
    templateCsvPath: 'config/sms/templates.csv',
    verificationTemplateNameLogin: '登录',
    verificationTemplateNameRegister: '注册',
    verificationTemplateNameResetPassword: '修改密码',
  ),
);
```

## 快速开始

### 基本使用

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';

class MyEndpoint extends Endpoint {
  Future<void> sendCode(Session session, String phone) async {
    final config = TencentSmsConfigServerpod.fromSession(
      session,
      appConfig: TencentSmsAppConfig(
        smsSdkAppId: '1400000000',
        signName: '你的签名',
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

### 与 serverpod_auth_sms 集成

```dart
import 'package:tencent_sms_serverpod/tencent_sms_serverpod.dart';
import 'package:serverpod_auth_sms/serverpod_auth_sms.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  final smsConfig = TencentSmsConfigServerpod.fromServerpod(
    pod,
    appConfig: TencentSmsAppConfig(
      smsSdkAppId: '1400000000',
      signName: '你的签名',
      templateCsvPath: 'config/sms/templates.csv',
      verificationTemplateNameLogin: '登录',
      verificationTemplateNameRegister: '注册',
      verificationTemplateNameResetPassword: '修改密码',
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

## API 参考

### TencentSmsAppConfig

非敏感配置：

```dart
TencentSmsAppConfig(
  smsSdkAppId: '1400000000',           // 必填
  signName: '你的签名',                 // 必填
  region: 'ap-guangzhou',               // 可选，默认: ap-guangzhou
  verificationTemplateId: '123456',     // 可选
  templateCsvPath: 'config/sms/templates.csv', // 可选
  verificationTemplateNameLogin: '登录',       // 可选
  verificationTemplateNameRegister: '注册',    // 可选
  verificationTemplateNameResetPassword: '修改密码', // 可选
)
```

### TencentSmsPasswordKeys

自定义 passwords.yaml 中的凭据键名：

```dart
TencentSmsPasswordKeys(
  secretId: 'myCustomSecretIdKey',   // 默认: tencentSmsSecretId
  secretKey: 'myCustomSecretKeyKey', // 默认: tencentSmsSecretKey
)
```

### SmsAuthCallbackHelper

为 `serverpod_auth_sms` 创建短信发送回调：

```dart
final helper = SmsAuthCallbackHelper(smsClient);

helper.sendForRegistration   // 注册验证码
helper.sendForLogin          // 登录验证码
helper.sendForBind           // 绑定验证码
helper.sendForResetPassword  // 重置密码验证码
```

## 常见问题

### 腾讯云频率限制错误

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| `LimitExceeded.PhoneNumberOneHourLimit` | 单手机号1小时内发送数量超限 | 等待或在控制台调整限制 |
| `LimitExceeded.PhoneNumberDailyLimit` | 单手机号日发送数量超限 | 同上 |
| `LimitExceeded.PhoneNumberThirtySecondLimit` | 30秒内发送频率超限 | 前端添加冷却时间 |

### 签名和模板审核

发送短信前需确保：
1. 短信签名已在腾讯云控制台审核通过
2. 短信模板已在腾讯云控制台审核通过
3. `signName` 配置值与审核通过的签名完全一致

## 相关包

- [tencent_sms](https://pub.dev/packages/tencent_sms) - 腾讯云短信核心包
- [serverpod_auth_sms](https://pub.dev/packages/serverpod_auth_sms) - Serverpod 短信认证

## 许可证

MIT License
