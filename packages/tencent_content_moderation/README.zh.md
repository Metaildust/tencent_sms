# tencent_content_moderation

[![pub package](https://img.shields.io/pub/v/tencent_content_moderation.svg)](https://pub.dev/packages/tencent_content_moderation)

腾讯云内容审核 Dart SDK（文本 + 图片），提供强类型请求/响应、统一审核结论和原始响应保留能力。

## 这个包覆盖什么

| 类型 | 腾讯云服务 | Action | 当前支持 |
| --- | --- | --- | --- |
| 文本 | TMS | `TextModeration` | Yes |
| 图片 | IMS | `ImageModeration` | Yes |
| 音频 | AMS | 异步任务接口 | 预留模型，暂未实现 |
| 视频 | VM | 异步任务接口 | 预留模型，暂未实现 |

## 开通与准备（腾讯云侧）

在代码接入之前，先完成以下步骤。

### 1) 开通文本与图片审核服务

- 内容安全控制台入口：`https://console.cloud.tencent.com/cms`
- 文本内容安全文档首页（TMS）：`https://cloud.tencent.com/document/product/1124`
- 文本快速入门（含开通与策略配置）：`https://cloud.tencent.com/document/product/1124/37119`
- 图片内容安全文档首页（IMS）：`https://cloud.tencent.com/document/product/1125`
- 图片快速入门（含开通与策略配置）：`https://cloud.tencent.com/document/product/1125/37109`

### 2) 创建策略并拿到 BizType

调用时传的 `bizType` 必须来自控制台已配置的策略。

- 文本接口文档（含 BizType 字段说明）：`https://cloud.tencent.com/document/api/1124/51860`
- 图片接口文档（含 BizType 字段说明）：`https://cloud.tencent.com/document/api/1125/53273`
- 控制台策略管理入口（应用管理）：`https://console.cloud.tencent.com/cms/clouds/manage`

建议按业务拆分 BizType，例如：

- `username`：用户名审核
- `scene`：教学内容审核

### 3) 创建并保存 SecretId / SecretKey

- API 密钥控制台：`https://console.cloud.tencent.com/cam/capi`
- 主账号密钥管理（英文文档）：`https://www.tencentcloud.com/document/product/598/34228`
- 子账号密钥管理（英文文档）：`https://www.tencentcloud.com/document/product/598/32675`

注意：`SecretKey` 创建后通常只展示一次，请立即妥善保存。

### 4) 子账号授权（推荐）

生产环境建议用子账号调用，最少需要文本和图片审核对应权限。

- IMS 子账号授权指引（含 `QcloudIMSFullAccess`）：`https://cloud.tencent.com/document/product/1125/107495`
- 内容安全权限管理说明（含 CAM 与 API 密钥说明）：`https://cloud.tencent.com/document/product/1125/60482`

若做最小权限自定义策略，可仅授权对应 Action（如 `tms:TextModeration`、`ims:ImageModeration`）和所需资源范围。

## 安装

```yaml
dependencies:
  tencent_content_moderation: ^0.1.0
```

## 快速开始

### 初始化客户端

```dart
import 'package:tencent_content_moderation/tencent_content_moderation.dart';
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

final client = TencentContentModerationClient(
  const TencentCloudApiConfig(
    secretId: 'your-secret-id',
    secretKey: 'your-secret-key',
    region: 'ap-guangzhou',
  ),
);
```

### 文本审核

```dart
final result = await client.moderateText(
  const TextModerationInput(
    content: '待审核文本',
    bizType: 'username',
    dataId: 'user-1001-name',
  ),
);

print(result.decision); // pass / review / block
print(result.label);
print(result.subLabel);
print(result.requestId);
```

### 图片审核（URL）

```dart
final result = await client.moderateImage(
  const ImageModerationInput(
    fileUrl: 'https://example.com/image.png',
    bizType: 'scene',
    dataId: 'problem-2001-image',
  ),
);

if (result.isBlock || result.isReview) {
  // 业务侧做拦截或人工复核
}
```

### 图片审核（Base64）

```dart
final result = await client.moderateImage(
  ImageModerationInput(
    fileBase64: imageBase64,
    bizType: 'scene',
    dataId: 'problem-2001-image-inline',
  ),
);
```

### 关闭客户端

```dart
client.close();
```

## 结果字段说明

- `decision`：统一结论，`pass` / `review` / `block`
- `label` / `subLabel`：主标签和子标签
- `hits`：结构化命中详情（标签、关键词、原始片段）
- `requestId`：腾讯云请求 ID，排障必备
- `rawResponse`：腾讯云原始响应，便于审计与回放

## 错误处理

```dart
try {
  final result = await client.moderateText(
    const TextModerationInput(content: 'hello', bizType: 'scene'),
  );
  print(result.decision);
} on TencentContentModerationApiException catch (e) {
  // 腾讯云业务错误（例如未开通服务、鉴权失败、参数不合法）
  print('api error: ${e.errorCode} ${e.errorMessage} requestId=${e.requestId}');
} on TencentContentModerationHttpException catch (e) {
  // HTTP 层错误
  print('http error: ${e.statusCode} body=${e.responseBody}');
} on TencentContentModerationResponseException catch (e) {
  // 响应结构不符合预期
  print('response parse error: ${e.message}');
}
```

## 生产接入建议

- 将密钥放在服务端安全配置中，不要放在客户端包体里。
- 对每条送审内容写入稳定 `dataId`，方便回查。
- 建议把 `requestId` 与业务日志关联。
- 对 `review` 和 `block` 建立明确业务分支（拦截、打回、人工审核）。
- 文本送审前可先做业务侧预处理（如去掉富文本嵌入）再送审。

## 官方文档索引

- 文本产品文档：`https://cloud.tencent.com/document/product/1124`
- 文本 API 概览：`https://cloud.tencent.com/document/product/1124/51870`
- 文本 `TextModeration`：`https://cloud.tencent.com/document/api/1124/51860`
- 图片产品文档：`https://cloud.tencent.com/document/product/1125`
- 图片 API 概览：`https://cloud.tencent.com/document/product/1125/53283`
- 图片 `ImageModeration`：`https://cloud.tencent.com/document/api/1125/53273`
- 内容安全控制台：`https://console.cloud.tencent.com/cms`
- API 密钥控制台：`https://console.cloud.tencent.com/cam/capi`

## License

MIT
