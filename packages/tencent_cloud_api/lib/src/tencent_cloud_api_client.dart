import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'tencent_cloud_api_config.dart';
import 'tencent_cloud_api_exception.dart';
import 'tencent_cloud_api_request.dart';

/// Log callback used by [TencentCloudApiClient].
typedef TencentCloudApiLogCallback = void Function(String message);

/// Generic Tencent Cloud API 3.0 client with TC3-HMAC-SHA256 signing.
class TencentCloudApiClient {
  static const Set<String> _reservedHeaderKeys = {
    'content-type',
    'host',
    'x-tc-action',
    'x-tc-version',
    'x-tc-region',
    'x-tc-timestamp',
    'x-tc-token',
    'authorization',
  };

  final TencentCloudApiConfig config;
  final http.Client _client;
  final bool _ownsClient;
  final TencentCloudApiLogCallback? _log;

  TencentCloudApiClient(
    this.config, {
    http.Client? client,
    TencentCloudApiLogCallback? log,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _log = log;

  /// Closes the owned HTTP client.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Sends a signed POST request and returns parsed JSON body.
  Future<Map<String, dynamic>> post(TencentCloudApiRequest request) async {
    _validateCustomHeaders(request.headers);

    final payloadJson = jsonEncode(request.payload);
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final authorization = _buildAuthorization(
      timestamp: timestamp,
      payload: payloadJson,
      host: request.host,
      action: request.action,
      service: request.service,
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Host': request.host,
      'X-TC-Action': request.action,
      'X-TC-Version': request.version,
      'X-TC-Region': request.region ?? config.region,
      'X-TC-Timestamp': '$timestamp',
      'Authorization': authorization,
      if (config.token != null && config.token!.isNotEmpty)
        'X-TC-Token': config.token!,
      ...request.headers,
    };

    final response = await _client.post(
      Uri.https(request.host, '/'),
      headers: headers,
      body: payloadJson,
    );

    if (response.statusCode != 200) {
      _log?.call(
        '[TencentCloudApi] http status error: '
        '${response.statusCode} ${response.body}',
      );
      throw TencentCloudApiHttpException(
        statusCode: response.statusCode,
        responseBody: response.body,
        message: 'Tencent Cloud API request failed',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw TencentCloudApiResponseException(
        message: 'Invalid JSON response',
        details: response.body,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw TencentCloudApiResponseException(
        message: 'Response JSON must be an object',
        details: response.body,
      );
    }

    return decoded;
  }

  void _validateCustomHeaders(Map<String, String> headers) {
    for (final key in headers.keys) {
      final normalized = key.trim().toLowerCase();
      if (_reservedHeaderKeys.contains(normalized)) {
        throw TencentCloudApiRequestException(
          message: 'Custom header "$key" is reserved by TencentCloudApiClient',
        );
      }
    }
  }

  String _buildAuthorization({
    required int timestamp,
    required String payload,
    required String host,
    required String action,
    required String service,
  }) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    final dateString = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';

    final canonicalHeaders = 'content-type:application/json\n'
        'host:${host.toLowerCase()}\n'
        'x-tc-action:${action.toLowerCase()}\n';
    const signedHeaders = 'content-type;host;x-tc-action';
    final hashedPayload = _sha256Hex(payload);
    final canonicalRequest =
        'POST\n/\n\n$canonicalHeaders\n$signedHeaders\n$hashedPayload';
    final hashedCanonicalRequest = _sha256Hex(canonicalRequest);

    final credentialScope = '$dateString/$service/tc3_request';
    final stringToSign = 'TC3-HMAC-SHA256\n'
        '$timestamp\n'
        '$credentialScope\n'
        '$hashedCanonicalRequest';

    final secretDate = _hmacSha256(
      utf8.encode('TC3${config.secretKey}'),
      dateString,
    );
    final secretService = _hmacSha256(secretDate, service);
    final secretSigning = _hmacSha256(secretService, 'tc3_request');
    final signature = _hmacSha256Hex(secretSigning, stringToSign);

    return 'TC3-HMAC-SHA256 '
        'Credential=${config.secretId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
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
