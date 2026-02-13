## 0.2.0

- Synchronized release version for the Tencent Cloud API package family
- Update dependency to `tencent_cloud_api: ^0.2.0`
- Keep `TencentSmsClient` API unchanged

## 0.1.3

- Remove local `dependency_overrides` from package pubspec for external publishing
- Update dependency to `tencent_cloud_api: ^0.1.1`

## 0.1.2

- Refactor Tencent Cloud API transport into `tencent_cloud_api`
- Keep `TencentSmsClient` public API unchanged while reusing shared TC3 signer/client
- Prepare shared foundation for other Tencent Cloud services (such as content moderation)

## 0.1.1

- **Breaking Change**: Error messages are now in English by default
- Added `SmsLocalizations` interface for custom error message localization
- Added `SmsLocalizationsEn` (English, default) and `SmsLocalizationsZh` (Chinese) implementations
- `TencentSmsClient` now accepts optional `localizations` parameter
- Updated all documentation comments to English
- Added comprehensive unit tests (46 tests)

## 0.1.0

- Initial release
- Support for sending verification codes
- Support for batch SMS sending
- Support for multi-scene templates (login/register/reset password)
- Support for CSV template mapping
- TC3-HMAC-SHA256 signature algorithm
- Auto phone number normalization to E.164 format
