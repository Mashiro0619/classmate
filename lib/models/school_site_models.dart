import 'dart:convert';

class SchoolSite {
  const SchoolSite({
    required this.name,
    required this.loginUrl,
  });

  final String name;
  final String loginUrl;

  factory SchoolSite.fromJson(Map<String, dynamic> json) {
    return SchoolSite(
      name: json['name'] as String? ?? '',
      loginUrl: json['loginUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'loginUrl': loginUrl,
  };

  SchoolSite copyWith({String? name, String? loginUrl}) {
    return SchoolSite(
      name: name ?? this.name,
      loginUrl: loginUrl ?? this.loginUrl,
    );
  }

  bool get isValid => name.trim().isNotEmpty && loginUrl.trim().isNotEmpty;
}

List<SchoolSite> decodeSchoolSites(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException('School site JSON format is invalid.');
  }
  return decoded
      .whereType<Map>()
      .map((item) => SchoolSite.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.isValid)
      .toList();
}

String encodeSchoolSites(List<SchoolSite> sites) {
  return const JsonEncoder.withIndent('  ').convert(
    sites.map((item) => item.toJson()).toList(),
  );
}
