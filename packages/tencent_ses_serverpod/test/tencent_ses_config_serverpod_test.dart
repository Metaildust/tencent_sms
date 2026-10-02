import 'package:tencent_ses_serverpod/tencent_ses_serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('default subjects are the Chinese verification titles', () {
    const config = TencentSesAppConfig(fromEmailAddress: 'sender@example.com');
    expect(config.subjectRegister, '验证码');
    expect(config.subjectResetPassword, '重置密码验证码');
  });
}
