import 'package:tencent_cloud_api_serverpod/tencent_cloud_api_serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('blank secretKey throws before it can be used', () {
    expect(
      () => TencentCloudApiConfigServerpod.readRequiredPassword(
        (key) => key == 'tencentSecretKey' ? '   ' : 'id',
        'tencentSecretKey',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
