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
