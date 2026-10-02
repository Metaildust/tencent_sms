## Unreleased

- Default registration subject is `验证码`
- Default password-reset subject is `重置密码验证码`
- Reject a blank `secretId` or `secretKey` before any request

## 0.1.1

- Treat a send as failed when `MessageId` is missing, empty, or whitespace-only

## 0.1.0

- Initial release
- Add Tencent Cloud SES `SendEmail` client for Dart/Flutter
- Add template-based verification email helpers
- Add unified exception and response models
