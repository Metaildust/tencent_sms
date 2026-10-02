<!-- Chinese translation: see [CHANGELOG.zh.md](CHANGELOG.zh.md). The
English version below is the source of truth; the Chinese file is a
courtesy translation kept in sync. -->

<!-- Publish date for 0.2.0 is to be backfilled. -->

## 0.2.0

### BREAKING CHANGES

- Removed `ContentModerationService.submitVideoModerationForStorage(...)`
  together with the COS direct-input mode in upstream
  `tencent_content_moderation` 0.2.0.
- Bumped `tencent_content_moderation` dependency to `^0.2.0`. The classes
  `BucketInfo` and `StorageInfo` are no longer re-exported because they
  were deleted in the SDK.

### Migration

Convert any `submitVideoModerationForStorage(StorageInfo.cos(...))` call
into a presigned `GET` URL on the caller-owned COS bucket and call
`submitVideoModeration(videoUrl, ...)` instead:

```dart
// before (0.1.x)
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

// after (0.2.0+)
final signedUrl = generatePresignedGetUrl(
  bucket: 'example-1250000000',
  region: 'ap-guangzhou',
  object: 'media/examples/problem-1/video.mp4',
  // expiresSeconds is illustrative; pick a TTL that comfortably
  // exceeds Tencent Cloud VM's async fetch window. The reference
  // Downstream application services often use 21600s (6h); do NOT go below 3600s
  // (1h) or VM may legitimately fail to fetch and the upstream
  // ERROR may be handled by your moderation safety guard as block.
  expiresSeconds: 21600,
);
await service.submitVideoModeration(
  signedUrl,
  dataId: 'video-1001',
  callbackUrl: 'https://api.example.com/moderation/callback',
);
```

The cross-account COS bucket policy granting Tencent Cloud VM
(`100004528167`) read access on caller-owned buckets is no longer
required for video moderation and can be removed.

When a video task fails or the raw response carries a structured error,
both `pass` and `review` are closed to `block` (`block` and a missing
suggestion stay unchanged; an in-progress task with no structured error
keeps `pass`). This release adds three public helpers: `videoTaskFailed`,
`closedVideoDecision`, and `closedVideoHits`.

## 0.1.0

- Initial release.
- Add Serverpod config helpers for moderation credentials and defaults.
- Add `ContentModerationService` and `ContentModerationServiceStore`.
