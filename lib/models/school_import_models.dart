Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

class SchoolImportPagePayload {
  const SchoolImportPagePayload({
    required this.url,
    required this.title,
    required this.html,
    required this.locale,
    this.sourceHint,
  });

  final String url;
  final String title;
  final String html;
  final String locale;
  final String? sourceHint;

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'html': html,
    'locale': locale,
    if (sourceHint != null && sourceHint!.trim().isNotEmpty)
      'sourceHint': sourceHint,
  };
}

class SchoolImportMeta {
  const SchoolImportMeta({
    required this.sourceUrl,
    required this.pageTitle,
    required this.parser,
    required this.warnings,
  });

  final String sourceUrl;
  final String pageTitle;
  final String parser;
  final List<String> warnings;

  factory SchoolImportMeta.fromJson(Map<String, dynamic> json) {
    return SchoolImportMeta(
      sourceUrl: json['sourceUrl'] as String? ?? '',
      pageTitle: json['pageTitle'] as String? ?? '',
      parser: json['parser'] as String? ?? '',
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
    );
  }
}

class ImportedPeriodTimeDraft {
  const ImportedPeriodTimeDraft({
    required this.index,
    required this.startMinutes,
    required this.endMinutes,
  });

  final int index;
  final int startMinutes;
  final int endMinutes;

  factory ImportedPeriodTimeDraft.fromJson(Map<String, dynamic> json) {
    return ImportedPeriodTimeDraft(
      index: (json['index'] as num?)?.toInt() ?? 1,
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 8 * 60,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? (8 * 60) + 45,
    );
  }
}

class ImportedPeriodTimeSetDraft {
  const ImportedPeriodTimeSetDraft({required this.name, required this.periodTimes});

  final String name;
  final List<ImportedPeriodTimeDraft> periodTimes;

  factory ImportedPeriodTimeSetDraft.fromJson(Map<String, dynamic> json) {
    return ImportedPeriodTimeSetDraft(
      name: json['name'] as String? ?? '',
      periodTimes: (json['periodTimes'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => ImportedPeriodTimeDraft.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class ImportedCourseDraft {
  const ImportedCourseDraft({
    required this.name,
    required this.teacher,
    required this.location,
    required this.dayOfWeek,
    required this.semesterWeeks,
    required this.periods,
    required this.startMinutes,
    required this.endMinutes,
    required this.credit,
    required this.remarks,
    required this.customFields,
  });

  final String name;
  final String teacher;
  final String location;
  final int dayOfWeek;
  final List<int> semesterWeeks;
  final List<int> periods;
  final int startMinutes;
  final int endMinutes;
  final double credit;
  final String remarks;
  final Map<String, dynamic> customFields;

  factory ImportedCourseDraft.fromJson(Map<String, dynamic> json) {
    return ImportedCourseDraft(
      name: json['name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      location: json['location'] as String? ?? '',
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      semesterWeeks: (json['semesterWeeks'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => (item as num).toInt())
          .toList(),
      periods: (json['periods'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => (item as num).toInt())
          .toList(),
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 8 * 60,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? (8 * 60) + 45,
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      remarks: json['remarks'] as String? ?? '',
      customFields: _asStringKeyedMap(json['customFields']),
    );
  }
}

class SchoolImportTimetableDraft {
  const SchoolImportTimetableDraft({
    required this.name,
    required this.startDate,
    required this.totalWeeks,
    required this.periodTimeSet,
    required this.courses,
  });

  final String name;
  final DateTime startDate;
  final int totalWeeks;
  final ImportedPeriodTimeSetDraft periodTimeSet;
  final List<ImportedCourseDraft> courses;

  factory SchoolImportTimetableDraft.fromJson(Map<String, dynamic> json) {
    final startDateRaw = json['startDate'] as String?;
    return SchoolImportTimetableDraft(
      name: json['name'] as String? ?? '',
      startDate: DateTime.tryParse(startDateRaw ?? '') ?? DateTime.now(),
      totalWeeks: (json['totalWeeks'] as num?)?.toInt() ?? 18,
      periodTimeSet: ImportedPeriodTimeSetDraft.fromJson(
        Map<String, dynamic>.from(json['periodTimeSet'] as Map? ?? const {}),
      ),
      courses: (json['courses'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => ImportedCourseDraft.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  SchoolImportTimetableDraft copyWith({
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    ImportedPeriodTimeSetDraft? periodTimeSet,
    List<ImportedCourseDraft>? courses,
  }) {
    return SchoolImportTimetableDraft(
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      periodTimeSet: periodTimeSet ?? this.periodTimeSet,
      courses: courses ?? this.courses,
    );
  }
}

class SchoolImportResponse {
  const SchoolImportResponse({required this.meta, required this.timetable});

  final SchoolImportMeta meta;
  final SchoolImportTimetableDraft timetable;

  factory SchoolImportResponse.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] as bool? ?? false;
    if (!ok) {
      throw FormatException(json['message'] as String? ?? 'Import failed.');
    }
    return SchoolImportResponse(
      meta: SchoolImportMeta.fromJson(
        Map<String, dynamic>.from(json['meta'] as Map? ?? const {}),
      ),
      timetable: SchoolImportTimetableDraft.fromJson(
        Map<String, dynamic>.from(json['timetable'] as Map? ?? const {}),
      ),
    );
  }

  SchoolImportResponse copyWith({
    SchoolImportMeta? meta,
    SchoolImportTimetableDraft? timetable,
  }) {
    return SchoolImportResponse(
      meta: meta ?? this.meta,
      timetable: timetable ?? this.timetable,
    );
  }
}
