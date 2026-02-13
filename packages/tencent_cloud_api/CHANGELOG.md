## 0.2.0

- Synchronized release version for the Tencent Cloud API package family
- Keep TC3 signer and request API stable
- Keep reserved-header protection for signature integrity

## 0.1.1

- Disallow overriding reserved signed headers in custom request headers
- Add `TencentCloudApiRequestException` for invalid request setup

## 0.1.0

- Initial release
- Add reusable TC3-HMAC-SHA256 signing for Tencent Cloud API 3.0
- Add generic HTTP JSON request client with Tencent Cloud headers
- Add request/config/exception models for service-specific wrappers
