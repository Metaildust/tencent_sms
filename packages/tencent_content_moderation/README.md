# tencent_content_moderation

[![pub package](https://img.shields.io/pub/v/tencent_content_moderation.svg)](https://pub.dev/packages/tencent_content_moderation)

Typed Dart SDK for Tencent Cloud content moderation APIs (text + image), with normalized verdicts and typed models.

## Coverage

| Content type | Tencent Cloud service | Action | Status |
| --- | --- | --- | --- |
| Text | TMS | `TextModeration` | Yes |
| Image | IMS | `ImageModeration` | Yes |
| Audio | AMS | Async task APIs | Models reserved, not implemented yet |
| Video | VM | Async task APIs | Models reserved, not implemented yet |

## Activation Checklist (Tencent Cloud)

Before using this package, complete the cloud-side setup.

### 1) Enable text and image moderation

- Console: `https://console.cloud.tencent.com/cms`
- TMS docs home: `https://cloud.tencent.com/document/product/1124`
- TMS quick start (enable + policy setup): `https://cloud.tencent.com/document/product/1124/37119`
- IMS docs home: `https://cloud.tencent.com/document/product/1125`
- IMS quick start (enable + policy setup): `https://cloud.tencent.com/document/product/1125/37109`

### 2) Create policies and obtain BizType

`bizType` must match a policy configured in the Tencent Cloud console.

- TMS `TextModeration` API docs (BizType parameter): `https://cloud.tencent.com/document/api/1124/51860`
- IMS `ImageModeration` API docs (BizType parameter): `https://cloud.tencent.com/document/api/1125/53273`
- Policy management entry: `https://console.cloud.tencent.com/cms/clouds/manage`

Suggested BizType split by business scene, for example:

- `username` for display name checks
- `scene` for teaching or question-bank content

### 3) Create SecretId / SecretKey

- API key console: `https://console.cloud.tencent.com/cam/capi`
- Root account key management: `https://www.tencentcloud.com/document/product/598/34228`
- Sub-account key management: `https://www.tencentcloud.com/document/product/598/32675`

### 4) Grant CAM permissions (recommended for sub-accounts)

- IMS sub-account authorization (includes `QcloudIMSFullAccess`): `https://cloud.tencent.com/document/product/1125/107495`
- CAM and permission overview for content safety: `https://cloud.tencent.com/document/product/1125/60482`

For least privilege, grant only required actions (such as `tms:TextModeration` and `ims:ImageModeration`) and proper resource scopes.

## Installation

```yaml
dependencies:
  tencent_content_moderation: ^0.1.0
```

## Features

- Text moderation (`TextModeration`)
- Image moderation (`ImageModeration`)
- Typed request/response models
- Normalized moderation verdict (`pass` / `review` / `block`)
- Raw Tencent response preserved for debugging and audits

## Quick Start

### Initialize client

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

### Moderate text

```dart
final result = await client.moderateText(
  const TextModerationInput(
    content: 'text to review',
    bizType: 'username',
    dataId: 'user-1001-name',
  ),
);

print(result.decision); // pass / review / block
print(result.label);
print(result.subLabel);
print(result.requestId);
```

### Moderate image (URL)

```dart
final result = await client.moderateImage(
  const ImageModerationInput(
    fileUrl: 'https://example.com/image.png',
    bizType: 'scene',
    dataId: 'problem-2001-image',
  ),
);
```

### Moderate image (Base64)

```dart
final result = await client.moderateImage(
  ImageModerationInput(
    fileBase64: imageBase64,
    bizType: 'scene',
    dataId: 'problem-2001-image-inline',
  ),
);
```

### Close client

```dart
client.close();
```

## Result Fields

- `decision`: normalized verdict (`pass`, `review`, `block`)
- `label` / `subLabel`: top-level and sub-level labels
- `hits`: structured hit details (labels, keywords, raw snippets)
- `requestId`: Tencent Cloud request id for troubleshooting
- `rawResponse`: full Tencent Cloud response for audit/debugging

## Error Handling

```dart
try {
  final result = await client.moderateText(
    const TextModerationInput(content: 'hello', bizType: 'scene'),
  );
  print(result.decision);
} on TencentContentModerationApiException catch (e) {
  // Tencent business-side error
  print('api error: ${e.errorCode} ${e.errorMessage} requestId=${e.requestId}');
} on TencentContentModerationHttpException catch (e) {
  // HTTP layer error
  print('http error: ${e.statusCode} body=${e.responseBody}');
} on TencentContentModerationResponseException catch (e) {
  // Invalid or unexpected response payload
  print('response parse error: ${e.message}');
}
```

## Production Recommendations

- Keep SecretId/SecretKey only on trusted backend systems.
- Always attach stable `dataId` to map moderation results to business objects.
- Persist `requestId` in logs for ticket-based troubleshooting.
- Define explicit business behavior for both `review` and `block`.
- Preprocess rich text before moderation if your business needs plain-text review.

## Official Docs

- TMS docs home: `https://cloud.tencent.com/document/product/1124`
- TMS API overview: `https://cloud.tencent.com/document/product/1124/51870`
- TMS `TextModeration`: `https://cloud.tencent.com/document/api/1124/51860`
- IMS docs home: `https://cloud.tencent.com/document/product/1125`
- IMS API overview: `https://cloud.tencent.com/document/product/1125/53283`
- IMS `ImageModeration`: `https://cloud.tencent.com/document/api/1125/53273`
- Content safety console: `https://console.cloud.tencent.com/cms`
- API key console: `https://console.cloud.tencent.com/cam/capi`

## License

MIT
