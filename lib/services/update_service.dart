import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.localVersion,
    required this.remoteVersion,
    required this.releaseUrl,
    required this.officialWebsiteUrl,
    required this.updateContent,
    required this.hasUpdate,
  });

  final String localVersion;
  final String remoteVersion;
  final String releaseUrl;
  final String officialWebsiteUrl;
  final String updateContent;
  final bool hasUpdate;
}

class _RemoteUpdateInfo {
  const _RemoteUpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.updateContent = '',
  });

  final String version;
  final String releaseUrl;
  final String updateContent;
}

class UpdateService {
  const UpdateService({http.Client? client}) : _client = client;

  static const _githubLatestApi =
      'https://api.github.com/repos/Mashiro0619/classmate/releases/latest';
  static const latestReleaseUrl =
      'https://github.com/Mashiro0619/classmate/releases/latest';

  final http.Client? _client;

  Future<UpdateCheckResult> checkForUpdates() async {
    final localVersion = await _getLocalVersion();
    final remoteInfo = await _getRemoteUpdateInfo();
    return UpdateCheckResult(
      localVersion: localVersion,
      remoteVersion: remoteInfo.version,
      releaseUrl: remoteInfo.releaseUrl,
      officialWebsiteUrl: AppConfig.officialWebsiteUrl,
      updateContent: remoteInfo.updateContent,
      hasUpdate: _compareVersions(remoteInfo.version, localVersion) > 0,
    );
  }

  Future<String> _getLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<_RemoteUpdateInfo> _getRemoteUpdateInfo() async {
    final client = _client ?? http.Client();
    final ownsClient = _client == null;
    try {
      if (AppConfig.hasUpdateVersionUrl) {
        try {
          return await _getCustomUpdateInfo(client);
        } on FormatException {
          rethrow;
        } catch (_) {}
      }
      return _getGithubLatestReleaseInfo(client);
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  Future<_RemoteUpdateInfo> _getCustomUpdateInfo(http.Client client) async {
    final response = await client.get(Uri.parse(AppConfig.updateVersionUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Unable to fetch custom update info.',
        Uri.parse(AppConfig.updateVersionUrl),
      );
    }
    final responseText = utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(responseText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid custom update response.');
    }
    final version = _normalizeVersion(decoded['version']?.toString() ?? '');
    if (version.isEmpty) {
      throw const FormatException('Custom update version is empty.');
    }
    return _RemoteUpdateInfo(
      version: version,
      releaseUrl: latestReleaseUrl,
      updateContent: decoded['updateContent']?.toString().trim() ?? '',
    );
  }

  Future<_RemoteUpdateInfo> _getGithubLatestReleaseInfo(http.Client client) async {
    final response = await client.get(
      Uri.parse(_githubLatestApi),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FormatException('Unable to fetch latest release version.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid latest release response.');
    }
    final tagName = decoded['tag_name']?.toString() ?? '';
    final version = _normalizeVersion(tagName);
    if (version.isEmpty) {
      throw const FormatException('Latest release version is empty.');
    }
    return _RemoteUpdateInfo(
      version: version,
      releaseUrl: decoded['html_url']?.toString().trim().isNotEmpty == true
          ? decoded['html_url'].toString().trim()
          : latestReleaseUrl,
      updateContent: decoded['body']?.toString().trim() ?? '',
    );
  }

  String _normalizeVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed.substring(1)
        : trimmed;
    return withoutPrefix.split('+').first.trim();
  }

  int _compareVersions(String a, String b) {
    final aParts = _normalizeVersion(a)
        .split('.')
        .map((item) => int.tryParse(item) ?? 0)
        .toList();
    final bParts = _normalizeVersion(b)
        .split('.')
        .map((item) => int.tryParse(item) ?? 0)
        .toList();
    final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var index = 0; index < maxLength; index++) {
      final left = index < aParts.length ? aParts[index] : 0;
      final right = index < bParts.length ? bParts[index] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }
}
