<!-- 这是 [CHANGELOG.md](CHANGELOG.md) 的中文翻译版。英文版是 source of truth，
本文件作为辅助翻译保持同步。如果两者出现歧义，以英文版为准。 -->

<!-- 0.2.0 的发布日期待回填。 -->

## 未发布

- 视频任务总建议为空时整单保持复审。明细里的拦截不会把整单改成拦截。
- 空白的 `secretId` 或 `secretKey` 在请求发出前拒绝。

## 0.2.0

### BREAKING CHANGES（破坏性变更）

- 删除视频审核的 COS 直传输入模式。`BucketInfo` 与 `StorageInfo`
  这两个类（含 `StorageInfo.url(...)` / `StorageInfo.cos(...)` 工厂方法）
  已被移除；`VideoModerationTaskInput.storageInfo` 字段与
  `VideoModerationTaskInput.resolvedStorageInfo` getter 同样移除。
  视频审核现在仅支持 URL 模式，`VideoModerationTaskInput.fileUrl` 是唯一
  必填的视频源。

### 为什么

腾讯云 VM 在 COS 直传路径上使用内部 STS 短期凭证拉对象，但其权限评估
在跨地域 / 跨账号组合下并不稳定。我们在生产化前的 staging 灰度阶段，
跨账号路径持续返回上游 `URL_ERROR / 403 Forbidden`，与此同时 VM 仍然
在响应里给出默认的 `Suggestion=Pass`，把"拉流失败"伪装成"审核通过"。
切到 URL 模式可以彻底绕开这种语义歧义：调用方在自己的桶上签出 URL，
上游错误也会变成确定性的失败。

### 迁移

把所有 `StorageInfo.cos(...)` 调用换成在调用方桶上自签的预签名 `GET`
URL（也可以是任何 VM 公网可达的 HTTPS 地址），并把它当作 `fileUrl` 传入：

```dart
// 改造前 (0.1.x)
final task = await client.createVideoModerationTask(
  VideoModerationTaskInput(
    storageInfo: StorageInfo.cos(
      bucketInfo: BucketInfo(
        bucket: 'example-1250000000',
        region: 'ap-guangzhou',
        object: 'media/examples/problem-1/video.mp4',
      ),
    ),
    bizType: 'scene',
    dataId: 'video-1001',
  ),
);

// 改造后 (0.2.0+)
final signedUrl = generatePresignedGetUrl(
  bucket: 'example-1250000000',
  region: 'ap-guangzhou',
  object: 'media/examples/problem-1/video.mp4',
  // expiresSeconds 仅作示意，请按业务挑一个能舒服覆盖腾讯云 VM 异步
  // 拉流窗口的 TTL。下游业务服务常用 21600s（6h）；
  // 不要低于 3600s（1h），否则 VM 真去拉流时可能合法地拉不到，导致
  // 上游 ERROR，可由消费侧审核安全策略兜底为 block。
  expiresSeconds: 21600,
);
final task = await client.createVideoModerationTask(
  VideoModerationTaskInput(
    fileUrl: signedUrl,
    bizType: 'scene',
    dataId: 'video-1001',
  ),
);
```

原本为腾讯云 VM（账号 `100004528167`）开通的、对调用方自有桶的"读权限"
跨账号 bucket policy 已经不再需要，可以撤回。

视频任务失败或响应带结构化错误时，把 `pass` 和 `review` 都关闭为 `block`
（`block` 与空建议保持原值；进行中且无结构化错误时保留 `pass`），并新增三个公开
helper：`videoTaskFailed`、`closedVideoDecision`、`closedVideoHits`。

## 0.1.0

- 首个版本。
- 提供文本与图片审核的强类型 API。
- 在 `tencent_cloud_api` 上构建 `TencentContentModerationClient`。
- 提供领域模型、解析容错与审核异常体系。
