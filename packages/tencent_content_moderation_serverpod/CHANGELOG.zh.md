<!-- 这是 [CHANGELOG.md](CHANGELOG.md) 的中文翻译版。英文版是 source of truth，
本文件作为辅助翻译保持同步。如果两者出现歧义，以英文版为准。 -->

<!-- 0.2.0 的发布日期待回填。 -->

## 0.2.0

### BREAKING CHANGES（破坏性变更）

- 删除 `ContentModerationService.submitVideoModerationForStorage(...)`，
  与上游 `tencent_content_moderation` 0.2.0 删除 COS 直传输入模式同步。
- 把对 `tencent_content_moderation` 的依赖提升到 `^0.2.0`。`BucketInfo`
  与 `StorageInfo` 这两个类已不再被 re-export，因为它们已经从 SDK 删除。

### 迁移

把所有 `submitVideoModerationForStorage(StorageInfo.cos(...))` 调用换成
在调用方桶上自签的预签名 `GET` URL，再调用 `submitVideoModeration(videoUrl, ...)`：

```dart
// 改造前 (0.1.x)
await service.submitVideoModerationForStorage(
  StorageInfo.cos(
    bucketInfo: BucketInfo(
      bucket: 'example-1250000000',
      region: 'ap-guangzhou',
      object: 'media/examples/problem-1/video.mp4',
    ),
  ),
  dataId: 'video-1001',
  callbackUrl: 'https://api.example.com/moderation/callback',
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
await service.submitVideoModeration(
  signedUrl,
  dataId: 'video-1001',
  callbackUrl: 'https://api.example.com/moderation/callback',
);
```

原本为腾讯云 VM（账号 `100004528167`）开通的、对调用方自有桶的"读权限"
跨账号 bucket policy 已经不再需要，可以撤回。

视频任务失败或原始响应带结构化错误时，把 `pass` 和 `review` 都关闭为
`block`（`block` 与空建议保持原值；进行中且无结构化错误时保留 `pass`），
并新增三个公开 helper：`videoTaskFailed`、`closedVideoDecision`、
`closedVideoHits`。

## 0.1.0

- 首个版本。
- 提供 Serverpod 风格的审核凭证与默认配置 helper。
- 提供 `ContentModerationService` 与 `ContentModerationServiceStore`。
