import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PrivacyService {
  const PrivacyService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<String?> fetchCurrentPrivacyPolicyVersion() async {
    try {
      final client = _client ?? http.Client();
      final ownsClient = _client == null;
      try {
        final uri = Uri.parse('https://mashiro.tech/KeSchedule/privacy.html');
        final response = await client.get(uri).timeout(
          const Duration(seconds: 10),
        );
        if (response.statusCode != 200) return null;
        final match = RegExp(
          r'<meta\s+name="privacy-policy-version"\s+content="([^"]*)"',
        ).firstMatch(response.body);
        if (match == null) return null;
        final version = match.group(1)!.trim();
        return version.isEmpty ? null : version;
      } finally {
        if (ownsClient) client.close();
      }
    } catch (e, st) {
      debugPrint('Failed to fetch privacy version: $e\n$st');
      return null;
    }
  }
}
