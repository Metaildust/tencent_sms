import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'sms_send_response.dart';
import 'sms_verification_scene.dart';
import 'tencent_sms_config.dart';
import 'tencent_sms_exception.dart';

/// 日志回调函数类型
typedef LogCallback = void Function(String message);

/// 腾讯云短信客户端
///
/// ## 基本用法
///
/// ```dart
/// final client = TencentSmsClient(config);
///
/// // 发送验证码
/// await client.sendVerificationCode(
///   phoneNumber: '+8613800138000',
///   verificationCode: '123456',
///   templateId: '123456',
/// );
///
/// // 批量发送
/// await client.sendSms(
///   phoneNumbers: ['+8613800138000', '+8613800138001'],
///   templateId: '123456',
///   templateParams: ['验证码内容'],
/// );
/// ```
class TencentSmsClient {
  static const _host = 'sms.tencentcloudapi.com';
  static const _service = 'sms';
  static const _version = '2021-01-11';

  final TencentSmsConfig config;
  final http.Client _client;
  final bool _ownsClient;
  final LogCallback? _log;

  Map<String, String>? _cachedTemplateIdByName;
  bool _templateMapLoaded = false;

  /// 创建腾讯云短信客户端
  ///
  /// [config] 腾讯云短信配置
  /// [client] 可选的 HTTP 客户端（用于测试或自定义）
  /// [log] 可选的日志回调
  TencentSmsClient(
    this.config, {
    http.Client? client,
    LogCallback? log,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _log = log;

  /// 关闭客户端
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// 发送验证码短信（单个手机号）
  ///
  /// [phoneNumber] 手机号码（支持 E.164 格式或国内 11 位号码）
  /// [verificationCode] 验证码内容
  /// [templateId] 模板 ID（可选，不提供时使用配置中的默认模板）
  /// [sessionContext] 用户自定义的 Session 内容
  /// [throwOnError] 发送失败时是否抛出异常
  Future<SmsSendResponse> sendVerificationCode({
    required String phoneNumber,
    required String verificationCode,
    String? templateId,
    String? sessionContext,
    bool throwOnError = true,
  }) async {
    final resolvedTemplateId = templateId ??
        await _resolveVerificationTemplateId(
          templateName: config.defaultLoginTemplateName,
        );

    if (resolvedTemplateId == null || resolvedTemplateId.isEmpty) {
      throw const TencentSmsConfigException(message: '未配置验证码模板 ID');
    }

    final response = await sendSms(
      phoneNumbers: [phoneNumber],
      templateId: resolvedTemplateId,
      templateParams: [verificationCode],
      sessionContext: sessionContext,
    );

    if (!response.isOk && throwOnError) {
      _log?.call(
        '[TencentSms] sendVerificationCode failed: '
        'requestId=${response.requestId}, '
        'error=${response.error?.code ?? 'UnknownError'} '
        '${response.error?.message ?? ''}',
      );
      throw TencentSmsSendException(
        message: '短信发送失败: ${response.error?.message ?? 'Unknown error'}',
        code: response.error?.code,
      );
    }

    return response;
  }

  /// 按场景发送验证码短信（单个手机号）
  ///
  /// [scene] 验证码场景（登录/注册/重置密码）
  /// [phoneNumber] 手机号码
  /// [verificationCode] 验证码内容
  /// [sessionContext] 用户自定义的 Session 内容
  /// [throwOnError] 发送失败时是否抛出异常
  Future<SmsSendResponse> sendVerificationCodeForScene({
    required SmsVerificationScene scene,
    required String phoneNumber,
    required String verificationCode,
    String? sessionContext,
    bool throwOnError = true,
  }) async {
    final templateName = config.templateNameForScene(scene);
    final templateId = await _resolveVerificationTemplateId(
      templateName: templateName,
    );

    if (templateId == null || templateId.isEmpty) {
      throw TencentSmsConfigException(
        message: '未配置场景 ${scene.name} 的验证码模板 ID',
      );
    }

    final response = await sendSms(
      phoneNumbers: [phoneNumber],
      templateId: templateId,
      templateParams: [verificationCode],
      sessionContext: sessionContext,
    );

    if (!response.isOk && throwOnError) {
      _log?.call(
        '[TencentSms] sendVerificationCodeForScene($scene) failed: '
        'requestId=${response.requestId}, '
        'error=${response.error?.code ?? 'UnknownError'} '
        '${response.error?.message ?? ''}',
      );
      throw TencentSmsSendException(
        message: '短信发送失败: ${response.error?.message ?? 'Unknown error'}',
        code: response.error?.code,
      );
    }

    return response;
  }

  /// 通用发送短信（支持批量）
  ///
  /// [phoneNumbers] 手机号码列表（支持 E.164 格式或国内 11 位号码）
  /// [templateId] 模板 ID
  /// [templateParams] 模板参数列表
  /// [signName] 短信签名（可选，默认使用配置中的签名）
  /// [smsSdkAppId] SDK AppID（可选，默认使用配置中的 AppID）
  /// [sessionContext] 用户自定义的 Session 内容
  /// [extendCode] 短信码号扩展号
  /// [senderId] 国际/港澳台短信 SenderId
  Future<SmsSendResponse> sendSms({
    required List<String> phoneNumbers,
    required String templateId,
    List<String> templateParams = const [],
    String? signName,
    String? smsSdkAppId,
    String? sessionContext,
    String? extendCode,
    String? senderId,
  }) async {
    if (phoneNumbers.isEmpty) {
      throw const TencentSmsConfigException(message: '手机号码不能为空');
    }

    final payload = <String, dynamic>{
      'PhoneNumberSet': phoneNumbers
          .map(_normalizePhoneNumber)
          .where((e) => e.isNotEmpty)
          .toList(),
      'SmsSdkAppId': smsSdkAppId ?? config.smsSdkAppId,
      'SignName': signName ?? config.signName,
      'TemplateId': templateId,
      'TemplateParamSet': templateParams,
      if (sessionContext != null) 'SessionContext': sessionContext,
      if (extendCode != null) 'ExtendCode': extendCode,
      if (senderId != null) 'SenderId': senderId,
    };

    final payloadJson = jsonEncode(payload);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final authorization = _buildAuthorization(
      timestamp: timestamp,
      payload: payloadJson,
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Host': _host,
      'X-TC-Action': 'SendSms',
      'X-TC-Version': _version,
      'X-TC-Region': config.region,
      'X-TC-Timestamp': '$timestamp',
      'Authorization': authorization,
    };

    final response = await _client.post(
      Uri.https(_host, '/'),
      headers: headers,
      body: payloadJson,
    );

    if (response.statusCode != 200) {
      _log?.call(
        '[TencentSms] http status error: ${response.statusCode} ${response.body}',
      );
      throw TencentSmsHttpException(
        statusCode: response.statusCode,
        message: '短信服务请求失败',
      );
    }

    final Map<String, dynamic> jsonBody =
        jsonDecode(response.body) as Map<String, dynamic>;
    return SmsSendResponse.fromJson(jsonBody);
  }

  Future<String?> _resolveVerificationTemplateId({
    String? templateName,
  }) async {
    final configuredId = config.verificationTemplateId;
    if (configuredId != null && configuredId.isNotEmpty) {
      return configuredId;
    }

    final csvPath = config.templateCsvPath?.trim();
    if (csvPath == null || csvPath.isEmpty) {
      return null;
    }

    final normalizedName = templateName?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return null;
    }

    final templateIdByName = await _loadTemplateIdMap(csvPath: csvPath);
    return templateIdByName[normalizedName];
  }

  Future<Map<String, String>> _loadTemplateIdMap({
    required String csvPath,
  }) async {
    if (_templateMapLoaded && _cachedTemplateIdByName != null) {
      return _cachedTemplateIdByName!;
    }
    _templateMapLoaded = true;

    final file = File(csvPath);
    if (!await file.exists()) {
      throw TencentSmsConfigException(
        message: '验证码模板 CSV 不存在: $csvPath',
      );
    }

    final bytes = await file.readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = utf8.decode(bytes, allowMalformed: true);
    }

    final templateIdByName = _buildTemplateIdMapFromCsv(text);
    _cachedTemplateIdByName = templateIdByName;
    return templateIdByName;
  }

  Map<String, String> _buildTemplateIdMapFromCsv(String csvText) {
    final lines = LineSplitter.split(csvText)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return {};

    final header = _parseCsvLine(lines.first);
    final headerIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final key = header[i].trim().toLowerCase();
      if (key.isNotEmpty) {
        headerIndex[key] = i;
      }
    }

    final idIndex = headerIndex['模板id'];
    final nameIndex = headerIndex['模板名称'];
    if (idIndex == null || nameIndex == null) {
      throw const TencentSmsConfigException(
        message: '验证码模板 CSV 表头不完整，请确保包含"模板ID"和"模板名称"，且文件为 UTF-8 编码',
      );
    }

    final result = <String, String>{};
    for (var i = 1; i < lines.length; i++) {
      final row = _parseCsvLine(lines[i]);
      if (row.length <= nameIndex || row.length <= idIndex) continue;
      final name = row[nameIndex].trim();
      final id = row[idIndex].trim();
      if (name.isNotEmpty && id.isNotEmpty) {
        result[name] = id;
      }
    }
    return result;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
          if (nextIsQuote) {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          result.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _buildAuthorization({
    required int timestamp,
    required String payload,
  }) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    final dateString = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';

    final canonicalHeaders = 'content-type:application/json\n'
        'host:$_host\n'
        'x-tc-action:sendsms\n';
    const signedHeaders = 'content-type;host;x-tc-action';
    final hashedPayload = _sha256Hex(payload);
    final canonicalRequest =
        'POST\n/\n\n$canonicalHeaders\n$signedHeaders\n$hashedPayload';
    final hashedCanonicalRequest = _sha256Hex(canonicalRequest);

    final credentialScope = '$dateString/$_service/tc3_request';
    final stringToSign = 'TC3-HMAC-SHA256\n'
        '$timestamp\n'
        '$credentialScope\n'
        '$hashedCanonicalRequest';

    final secretDate = _hmacSha256(
      utf8.encode('TC3${config.secretKey}'),
      dateString,
    );
    final secretService = _hmacSha256(secretDate, _service);
    final secretSigning = _hmacSha256(secretService, 'tc3_request');
    final signature = _hmacSha256Hex(secretSigning, stringToSign);

    return 'TC3-HMAC-SHA256 '
        'Credential=${config.secretId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
  }

  /// 标准化手机号码为 E.164 格式
  String _normalizePhoneNumber(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('+')) return value;
    if (value.startsWith('00')) {
      return '+${value.substring(2)}';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    // 中国大陆 11 位手机号
    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return '+86$digitsOnly';
    }
    return value;
  }

  List<int> _hmacSha256(List<int> key, String msg) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(msg)).bytes;
  }

  String _hmacSha256Hex(List<int> key, String msg) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(msg)).toString();
  }

  String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
