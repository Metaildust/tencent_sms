# tencent_content_moderation_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_content_moderation_serverpod.svg)](https://pub.dev/packages/tencent_content_moderation_serverpod)

Serverpod integration for `tencent_content_moderation`.

This package helps you:

- load Tencent credentials from `passwords.yaml`
- configure default region and BizType values
- use a server-oriented `ContentModerationService`
- share a process-level singleton via `ContentModerationServiceStore`

## When to use this package

Use this package if your Serverpod backend needs moderation for:

- username/profile updates
- publish-time text checks (title/body/answer/explanation)
- image URL moderation
- unified moderation entrypoints across endpoints/services

## Installation

```yaml
dependencies:
  tencent_content_moderation_serverpod: ^0.1.0
```

## Tencent Cloud Activation Checklist

This package does not activate Tencent Cloud services automatically.
Complete cloud-side setup first.

### 1) Enable text and image moderation

- Console: `https://console.cloud.tencent.com/cms`
- TMS quick start (enable + policy setup): `https://cloud.tencent.com/document/product/1124/37119`
- IMS quick start (enable + policy setup): `https://cloud.tencent.com/document/product/1125/37109`

### 2) Create policies and BizType values

- TMS `TextModeration` docs: `https://cloud.tencent.com/document/api/1124/51860`
- IMS `ImageModeration` docs: `https://cloud.tencent.com/document/api/1125/53273`
- Policy management entry: `https://console.cloud.tencent.com/cms/clouds/manage`

### 3) Create SecretId / SecretKey

- API key console: `https://console.cloud.tencent.com/cam/capi`
- Root account key management: `https://www.tencentcloud.com/document/product/598/34228`
- Sub-account key management: `https://www.tencentcloud.com/document/product/598/32675`

### 4) Grant CAM permissions

- IMS sub-account authorization (`QcloudIMSFullAccess`): `https://cloud.tencent.com/document/product/1125/107495`
- CAM and permission overview for content safety: `https://cloud.tencent.com/document/product/1125/60482`

## Serverpod Configuration

### 1) Put secrets in `passwords.yaml`

`passwords.yaml` (credentials only):

```yaml
shared:
  tencentModerationSecretId: 'your-secret-id'
  tencentModerationSecretKey: 'your-secret-key'
```

Optional STS token:

```yaml
shared:
  tencentModerationToken: 'optional-sts-token'
```

### 2) Configure non-sensitive defaults in code

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

### 3) Initialize service (recommended in `server.dart`)

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

## Quick Start

```dart
import 'package:tencent_content_moderation_serverpod/tencent_content_moderation_serverpod.dart';

final service = ContentModerationService(moderationConfig);

final verdict = await service.reviewText(
  'some content',
  dataId: 'post-1001-title',
);

if (verdict.isBlock) {
  // reject content
}
```

### Review image URL

```dart
final verdict = await ContentModerationServiceStore.instance.reviewImageUrl(
  'https://example.com/image.png',
  dataId: 'image-2001',
);
```

### Override default BizType (optional)

```dart
final verdict = await ContentModerationServiceStore.instance.reviewText(
  'content to review',
  bizType: 'username',
  dataId: 'user-1001-name',
);
```

### Attach user/device context (optional)

```dart
final verdict = await ContentModerationServiceStore.instance.reviewText(
  'content to review',
  user: const ModerationUser(userId: 'u-1001'),
  device: const ModerationDevice(ip: '1.2.3.4', platform: 'ios'),
);
```

## Verdict and Operational Notes

- `verdict.decision`: `pass`, `review`, `block`
- `verdict.requestId`: use in logs and support tickets
- `verdict.hits` / `verdict.rawResponse`: use for detailed rejection payloads

Recommended behavior:

- treat `review` and `block` as rejection in strict workflows
- make `dataId` stable and traceable
- persist `requestId` with business logs

## Troubleshooting

- `UnauthorizedOperation.Unauthorized`:
  - verify service activation
  - verify package balance/billing
  - verify CAM permissions
- BizType errors:
  - verify policy exists in console
  - ensure you pass BizType code, not display name
- `ContentModerationServiceStore not configured`:
  - call `ContentModerationServiceStore.configure(...)` during startup

## Official Docs

- TMS docs home: `https://cloud.tencent.com/document/product/1124`
- TMS `TextModeration`: `https://cloud.tencent.com/document/api/1124/51860`
- IMS docs home: `https://cloud.tencent.com/document/product/1125`
- IMS `ImageModeration`: `https://cloud.tencent.com/document/api/1125/53273`
- Content safety console: `https://console.cloud.tencent.com/cms`
- API key console: `https://console.cloud.tencent.com/cam/capi`

## License

MIT
