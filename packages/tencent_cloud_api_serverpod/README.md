# tencent_cloud_api_serverpod

[![pub package](https://img.shields.io/pub/v/tencent_cloud_api_serverpod.svg)](https://pub.dev/packages/tencent_cloud_api_serverpod)

Serverpod helpers for loading Tencent Cloud API credentials from `passwords.yaml`.

## Installation

```yaml
dependencies:
  tencent_cloud_api_serverpod: ^0.2.0
```

## Usage

```yaml
shared:
  tencentSecretId: 'your-secret-id'
  tencentSecretKey: 'your-secret-key'
```

```dart
import 'package:tencent_cloud_api_serverpod/tencent_cloud_api_serverpod.dart';

final apiConfig = TencentCloudApiConfigServerpod.fromServerpod(
  pod,
  appConfig: const TencentCloudApiAppConfig(
    region: 'ap-guangzhou',
  ),
);
```

## License

MIT
