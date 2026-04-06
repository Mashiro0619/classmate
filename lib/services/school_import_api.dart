import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/school_import_models.dart';

class SchoolImportApiResult {
  const SchoolImportApiResult({
    required this.response,
    required this.rawBody,
    required this.statusCode,
  });

  final SchoolImportResponse response;
  final String rawBody;
  final int statusCode;
}

class SchoolImportApi {
  const SchoolImportApi({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<SchoolImportResponse> importCurrentPage(
    SchoolImportPagePayload payload,
  ) async {
    final result = await importCurrentPageWithRawResponse(payload);
    return result.response;
  }

  Future<SchoolImportApiResult> importCurrentPageWithRawResponse(
    SchoolImportPagePayload payload,
  ) async {
    if (!AppConfig.hasSchoolImportApiBaseUrl) {
      throw const FormatException('School import API base URL is not configured.');
    }

    final client = _client ?? http.Client();
    final ownsClient = _client == null;
    try {
      final baseUri = Uri.parse(AppConfig.schoolImportApiBaseUrl);
      final path = baseUri.path.trim().toLowerCase().endsWith('.php')
          ? baseUri.path
          : _joinPath(baseUri.path, 'api.php');
      final uri = baseUri.replace(
        path: path,
        queryParameters: const {'action': 'import_timetable'},
      );
      final response = await client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload.toJson()),
      );
      final rawBody = response.body;
      final decoded = _tryDecodeJson(rawBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractErrorMessage(decoded);
        throw FormatException(
          message ?? 'Import request failed (${response.statusCode}).\n\n$rawBody',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Import response format is invalid.\n\n$rawBody');
      }
      if (decoded['ok'] == false) {
        throw FormatException(_extractErrorMessage(decoded) ?? 'Import failed.');
      }
      try {
        return SchoolImportApiResult(
          response: SchoolImportResponse.fromJson(decoded),
          rawBody: rawBody,
          statusCode: response.statusCode,
        );
      } on FormatException {
        rethrow;
      } catch (error) {
        throw FormatException('Import response parse failed.\n\n$rawBody\n\n$error');
      }
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Unable to connect to the import service.\n\n$error');
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  Map<String, dynamic>? _tryDecodeJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _extractErrorMessage(Map<String, dynamic>? json) {
    final message = json?['message']?.toString().trim();
    if (message == null || message.isEmpty) {
      return null;
    }
    return message;
  }

  String _joinPath(String basePath, String child) {
    final trimmedBase = basePath.trim();
    if (trimmedBase.isEmpty || trimmedBase == '/') {
      return '/$child';
    }
    final normalizedBase = trimmedBase.endsWith('/')
        ? trimmedBase.substring(0, trimmedBase.length - 1)
        : trimmedBase;
    return '$normalizedBase/$child';
  }
}
