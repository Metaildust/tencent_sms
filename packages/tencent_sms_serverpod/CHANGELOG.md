## 0.1.2

- **Breaking**: Separate sensitive and non-sensitive configuration
  - Add `TencentSmsAppConfig` for non-sensitive config (required)
  - Add `TencentSmsPasswordKeys` for customizing credential keys
  - `appConfig` is now required in `fromSession()` and `fromServerpod()`
- Only credentials (secretId, secretKey) should be in passwords.yaml
- Removed legacy fallback for reading non-sensitive config from passwords.yaml

## 0.1.1

- Updated all documentation comments to English
- `SmsAuthCallbackHelper` methods now return `Future<void>` for proper async handling
- Support for localization through `tencent_sms` package
- Updated to require `tencent_sms: ^0.1.1`

## 0.1.0

- Initial release
- TencentSmsConfigServerpod for reading config from passwords.yaml
- SmsAuthCallbackHelper for serverpod_auth_sms integration
