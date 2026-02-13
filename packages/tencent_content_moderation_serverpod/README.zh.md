# tencent_content_moderation_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_content_moderation_serverpod.svg)](https://pub.dev/packages/tencent_content_moderation_serverpod)

`tencent_content_moderation` 的 Serverpod 集成封装，负责：

- 从 `passwords.yaml` 读取密钥
- 生成 `ContentModerationService` 并统一调用文本/图片审核
- 输出服务端业务更易使用的 `ContentModerationVerdict`

## 适用场景

如果你在 Serverpod 后端需要做以下事情，建议使用本包：

- 用户昵称、资料字段审核
- 题目/答案/解析等发布前审核
- 图片 URL 审核
- 审核服务统一接入（含默认 BizType）

## 安装

```yaml
dependencies:
  tencent_content_moderation_serverpod: ^0.1.0
```

## 开通与准备（腾讯云侧）

本包不会自动帮你开通云服务。请先完成腾讯云侧配置，再接入代码。

### 1) 开通文本与图片审核

- 控制台：`https://console.cloud.tencent.com/cms`
- 文本快速入门（含开通、策略配置）：`https://cloud.tencent.com/document/product/1124/37119`
- 图片快速入门（含开通、策略配置）：`https://cloud.tencent.com/document/product/1125/37109`

### 2) 创建策略并拿到 BizType

- 文本接口参数说明（`TextModeration`）：`https://cloud.tencent.com/document/api/1124/51860`
- 图片接口参数说明（`ImageModeration`）：`https://cloud.tencent.com/document/api/1125/53273`
- 策略管理入口：`https://console.cloud.tencent.com/cms/clouds/manage`

建议按业务拆分 BizType，例如：

- `username`：用户昵称/名称审核
- `scene`：教学内容审核

### 3) 创建 SecretId / SecretKey

- API 密钥控制台：`https://console.cloud.tencent.com/cam/capi`
- 主账号密钥管理（英文文档）：`https://www.tencentcloud.com/document/product/598/34228`
- 子账号密钥管理（英文文档）：`https://www.tencentcloud.com/document/product/598/32675`

### 4) 子账号权限授权

- IMS 子账号授权（含 `QcloudIMSFullAccess`）：`https://cloud.tencent.com/document/product/1125/107495`
- 内容安全权限管理说明：`https://cloud.tencent.com/document/product/1125/60482`

## Serverpod 配置

### 1) 在 `passwords.yaml` 放敏感信息

`passwords.yaml`（仅敏感信息）：

```yaml
shared:
  tencentModerationSecretId: 'your-secret-id'
  tencentModerationSecretKey: 'your-secret-key'
```

如使用临时凭证，可额外配置：

```yaml
shared:
  tencentModerationToken: 'optional-sts-token'
```

### 2) 在代码里设置非敏感默认值（region / 默认 BizType）

```dart
final moderationConfig = TencentContentModerationConfigServerpod.fromServerpod(
  pod,
  appConfig: const TencentContentModerationAppConfig(
    region: 'ap-guangzhou',
    defaultTextBizType: 'default-text-policy',
    defaultImageBizType: 'default-image-policy',
  ),
);
```

### 3) 初始化服务（建议在 `server.dart`）

```dart
import 'package:tencent_content_moderation_serverpod/tencent_content_moderation_serverpod.dart';

final moderationConfig = TencentContentModerationConfigServerpod.fromServerpod(
  pod,
  appConfig: const TencentContentModerationAppConfig(
    region: 'ap-guangzhou',
    defaultTextBizType: 'username',
    defaultImageBizType: 'scene',
  ),
);

final service = ContentModerationService(moderationConfig);
ContentModerationServiceStore.configure(service: service);
```

## 快速使用

### 文本审核

```dart
final verdict = await service.reviewText(
  'some content',
  dataId: 'post-1001-title',
);

if (verdict.isBlock) {
  // 拒绝该内容
}
```

### 图片 URL 审核

```dart
final verdict = await ContentModerationServiceStore.instance.reviewImageUrl(
  'https://example.com/image.png',
  dataId: 'image-2001',
);
```

### 覆盖默认 BizType（可选）

```dart
final verdict = await ContentModerationServiceStore.instance.reviewText(
  '需要审核的文本',
  bizType: 'username',
  dataId: 'user-1001-name',
);
```

### 传递用户/设备上下文（可选）

```dart
final verdict = await ContentModerationServiceStore.instance.reviewText(
  '需要审核的文本',
  user: const ModerationUser(userId: 'u-1001'),
  device: const ModerationDevice(ip: '1.2.3.4', platform: 'ios'),
);
```

## 返回值与业务建议

- `verdict.decision`: `pass` / `review` / `block`
- `verdict.requestId`: 可直接用于排障
- `verdict.hits` / `verdict.rawResponse`: 便于构造业务违规详情

建议：

- 对 `review` 与 `block` 都执行业务拦截（或进入人工审核流程）
- 按业务对象维度稳定生成 `dataId`
- 把 `requestId` 写入日志

## 常见问题排查

- 返回 `UnauthorizedOperation.Unauthorized`：
  - 检查服务是否开通
  - 检查套餐/余额
  - 检查子账号 CAM 权限
- 返回 BizType 相关错误：
  - 检查控制台策略是否存在、拼写是否一致
  - 传入的是 BizType 编号，不是展示名称
- 服务端 `StateError: ContentModerationServiceStore not configured`：
  - 在 `server.dart` 启动阶段先执行 `ContentModerationServiceStore.configure(...)`

## 官方文档索引

- 文本产品文档：`https://cloud.tencent.com/document/product/1124`
- 文本 `TextModeration`：`https://cloud.tencent.com/document/api/1124/51860`
- 图片产品文档：`https://cloud.tencent.com/document/product/1125`
- 图片 `ImageModeration`：`https://cloud.tencent.com/document/api/1125/53273`
- 内容安全控制台：`https://console.cloud.tencent.com/cms`
- API 密钥控制台：`https://console.cloud.tencent.com/cam/capi`

## License

MIT
