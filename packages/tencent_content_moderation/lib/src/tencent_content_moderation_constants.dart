/// Tencent Cloud content moderation API constants.
class TencentContentModerationApiConstants {
  TencentContentModerationApiConstants._();

  static const String textHost = 'tms.tencentcloudapi.com';
  static const String textService = 'tms';
  static const String textAction = 'TextModeration';
  static const String textVersion = '2020-12-29';

  static const String imageHost = 'ims.tencentcloudapi.com';
  static const String imageService = 'ims';
  static const String imageAction = 'ImageModeration';
  static const String imageVersion = '2020-12-29';

  // Phase-2 extension points for async moderation tasks.
  static const String audioHost = 'ams.tencentcloudapi.com';
  static const String videoHost = 'vm.tencentcloudapi.com';
}
