import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tencent_cloud_api/tencent_cloud_api.dart';

import 'sms_localizations.dart';
import 'sms_send_response.dart';
import 'sms_verification_scene.dart';
import 'tencent_sms_config.dart';
import 'tencent_sms_exception.dart';

/// Log callback function type.
typedef LogCallback = void Function(String message);

/// Tencent Cloud SMS Client.
///
/// ## Basic Usage
///
/// ```dart
/// final client = TencentSmsClient(config);
///
/// // Send verification code
/// await client.sendVerificationCode(
///   phoneNumber: '+8613800138000',
///   verificationCode: '123456',
///   templateId: '123456',
/// );
///
/// // Batch send
/// await client.sendSms(
///   phoneNumbers: ['+8613800138000', '+8613800138001'],
///   templateId: '123456',
///   templateParams: ['123456'],
/// );
/// ```
///
/// ## Localization
///
/// By default, error messages are in English. To use Chinese messages:
///
/// ```dart
/// final client = TencentSmsClient(
///   config,
///   localizations: const SmsLocalizationsZh(),
/// );
/// ```
///
/// Or provide your own implementation:
///
/// ```dart
/// class MySmsLocalizations implements SmsLocalizations {
///   // ... your custom messages
/// }
/// ```
class TencentSmsClient {
  static const _host = 'sms.tencentcloudapi.com';
  static const _service = 'sms';
  static const _version = '2021-01-11';

  final TencentSmsConfig config;
  final SmsLocalizations localizations;
  final LogCallback? _log;
  late final TencentCloudApiClient _apiClient;

  Map<String, String>? _cachedTemplateIdByName;
  bool _templateMapLoaded = false;

  /// Creates a Tencent Cloud SMS client.
  ///
  /// [config] Tencent Cloud SMS configuration.
  /// [localizations] Error message localizations (default: English).
  /// [client] Optional HTTP client (for testing or customization).
  /// [log] Optional log callback.
  TencentSmsClient(
    this.config, {
    SmsLocalizations localizations = const SmsLocalizationsEn(),
    http.Client? client,
    LogCallback? log,
  })  : localizations = localizations,
        _log = log {
    _apiClient = TencentCloudApiClient(
      TencentCloudApiConfig(
        secretId: config.secretId,
        secretKey: config.secretKey,
        region: config.region,
      ),
      client: client,
      log: log == null ? null : (message) => log('[TencentSmsApi] $message'),
    );
  }

  /// 关闭客户端
  void close() {
    _apiClient.close();
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
      throw TencentSmsConfigException(
        message: localizations.verificationTemplateNotConfigured,
      );
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
        message: localizations.smsSendFailed(
          response.error?.message ?? 'Unknown error',
        ),
        code: response.error?.code,
      );
    }

    return response;
  }

  /// Send verification code by scene (single phone number).
  ///
  /// [scene] Verification scene (login/register/resetPassword).
  /// [phoneNumber] Phone number.
  /// [verificationCode] Verification code content.
  /// [sessionContext] Custom session content.
  /// [throwOnError] Whether to throw exception on failure.
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
        message: localizations.verificationTemplateNotConfiguredForScene(
          scene.name,
        ),
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
        message: localizations.smsSendFailed(
          response.error?.message ?? 'Unknown error',
        ),
        code: response.error?.code,
      );
    }

    return response;
  }

  /// General SMS sending (supports batch).
  ///
  /// [phoneNumbers] Phone number list (supports E.164 format or 11-digit Chinese numbers).
  /// [templateId] Template ID.
  /// [templateParams] Template parameter list.
  /// [signName] SMS signature (optional, defaults to config value).
  /// [smsSdkAppId] SDK AppID (optional, defaults to config value).
  /// [sessionContext] Custom session content.
  /// [extendCode] SMS code extension number.
  /// [senderId] International/HK/Macau/Taiwan SMS SenderId.
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
      throw TencentSmsConfigException(
        message: localizations.phoneNumbersEmpty,
      );
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

    try {
      final jsonBody = await _apiClient.post(
        TencentCloudApiRequest(
          host: _host,
          service: _service,
          action: 'SendSms',
          version: _version,
          payload: payload,
        ),
      );
      return SmsSendResponse.fromJson(jsonBody);
    } on TencentCloudApiHttpException catch (e) {
      throw TencentSmsHttpException(
        statusCode: e.statusCode,
        message: localizations.httpRequestFailed,
      );
    } on TencentCloudApiResponseException catch (e) {
      _log?.call('[TencentSms] invalid response: $e');
      throw TencentSmsSendException(
        message: localizations.smsSendFailed(e.message),
        code: e.code,
      );
    } on TencentCloudApiException catch (e) {
      _log?.call('[TencentSms] api error: $e');
      throw TencentSmsSendException(
        message: localizations.smsSendFailed(e.message),
        code: e.code,
      );
    }
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
        message: localizations.templateCsvNotFound(csvPath),
      );
    }

    final bytes = await file.readAsBytes();
    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = utf8.decode(bytes, allowMalformed: true);
    }

    final templateIdByName = _buildTemplateIdMapFromCsv(
      text,
      localizations: localizations,
    );
    _cachedTemplateIdByName = templateIdByName;
    return templateIdByName;
  }

  Map<String, String> _buildTemplateIdMapFromCsv(
    String csvText, {
    required SmsLocalizations localizations,
  }) {
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

    // Tencent Cloud CSV export uses Chinese headers
    final idIndex = headerIndex['模板id'];
    final nameIndex = headerIndex['模板名称'];
    if (idIndex == null || nameIndex == null) {
      throw TencentSmsConfigException(
        message: localizations.templateCsvInvalidHeader,
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
}
