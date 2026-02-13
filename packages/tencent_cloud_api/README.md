# tencent_cloud_api

[![pub package](https://img.shields.io/pub/v/tencent_cloud_api.svg)](https://pub.dev/packages/tencent_cloud_api)

Tencent Cloud API 3.0 core client for Dart/Flutter.

This package provides:

- TC3-HMAC-SHA256 signing
- Generic JSON POST request flow for `*.tencentcloudapi.com`
- Reusable request/config/exception models

## Installation

```yaml
dependencies:
  tencent_cloud_api: ^0.2.0
```

## Quick Start

```dart
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

void main() async {
  final client = TencentCloudApiClient(
    const TencentCloudApiConfig(
      secretId: 'your-secret-id',
      secretKey: 'your-secret-key',
      region: 'ap-guangzhou',
    ),
  );

  final body = await client.post(
    const TencentCloudApiRequest(
      host: 'tms.tencentcloudapi.com',
      service: 'tms',
      action: 'TextModeration',
      version: '2020-12-29',
      payload: <String, dynamic>{
        'Content': '5L2g5aW9', // base64 text
      },
    ),
  );

  print(body);
  client.close();
}
```

## Notes

- This package is intentionally low-level.
- Service-specific business parsing should stay in higher-level wrappers.
- For temporary credentials, pass `token` in `TencentCloudApiConfig`.

## License

MIT
