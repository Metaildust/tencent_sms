<!-- Chinese translation: see [CHANGELOG.zh.md](CHANGELOG.zh.md). The
English version below is the source of truth; the Chinese file is a
courtesy translation kept in sync. -->

<!-- Publish date for 0.2.0 is to be backfilled. -->

## Unreleased

- An empty video-task suggestion stays review. A detail Block does not raise the task decision to block.
- Reject a blank `secretId` or `secretKey` before any request

## 0.2.0

### BREAKING CHANGES

- Removed COS direct input mode for video moderation. The classes
  `BucketInfo` and `StorageInfo` (including `StorageInfo.url(...)` and
  `StorageInfo.cos(...)` factories) are deleted. The
  `VideoModerationTaskInput.storageInfo` field and the
  `VideoModerationTaskInput.resolvedStorageInfo` getter are also removed.
  Video moderation is now URL-only and `VideoModerationTaskInput.fileUrl`
  is the single required source.

### Why

Tencent Cloud VM evaluates the COS direct input path with internal STS
temporary credentials whose permission resolution is not stable across
regions and account combinations. In our production rollout the cross-
account path produced an upstream `URL_ERROR / 403 Forbidden` while VM
still returned a default `Suggestion=Pass`, masking the failure as a
successful pass. The URL path bypasses that ambiguity entirely: the
caller signs its own URL on its own bucket and the upstream error
surface becomes deterministic.

### Migration

Replace any `StorageInfo.cos(...)` call site with a presigned `GET` URL
generated against the caller-owned COS bucket (or any HTTPS origin that
VM can reach), and pass it as `fileUrl`:

```dart
// before (0.1.x)
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
final task = await client.createVideoModerationTask(
  VideoModerationTaskInput(
    fileUrl: signedUrl,
    bizType: 'scene',
    dataId: 'video-1001',
  ),
);
```

The cross-account COS bucket policy granting Tencent Cloud VM
(`100004528167`) read access on caller-owned buckets is no longer
required for video moderation and can be removed.

When a video task fails or the response carries a structured error,
both `pass` and `review` are closed to `block` (`block` and a missing
suggestion stay unchanged; an in-progress task with no structured error
keeps `pass`). This release adds three public helpers: `videoTaskFailed`,
`closedVideoDecision`, and `closedVideoHits`.

## 0.1.0

- Initial release with typed text and image moderation APIs.
- Add `TencentContentModerationClient` built on `tencent_cloud_api`.
- Add domain models, parsing safeguards, and moderation exceptions.
