import 'dart:convert';

import '../l10n/app_locale.dart';
import '../utils/localized_names.dart';
import '../utils/time_utils.dart';
import 'course_item.dart';

class TimetableConfig {
  const TimetableConfig({
    required this.name,
    required this.startDate,
    required this.totalWeeks,
    required this.periodTimeSetId,
  });

  final String name;
  final DateTime startDate;
  final int totalWeeks;
  final String periodTimeSetId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'startDate': startDate.toIso8601String(),
    'totalWeeks': totalWeeks,
    'periodTimeSetId': periodTimeSetId,
  };

  factory TimetableConfig.fromJson(
    Map<String, dynamic> json, {
    String localeCode = defaultLocaleCode,
  }) {
    final startDateValue = json['startDate'] as String?;
    return TimetableConfig(
      name:
          json['name'] as String? ??
          untitledTimetableName(localeCode: localeCode),
      startDate: DateTime.tryParse(startDateValue ?? '') ?? DateTime.now(),
      totalWeeks: normalizeTimetableWeeks((json['totalWeeks'] as num?)?.toInt()),
      periodTimeSetId: json['periodTimeSetId'] as String? ?? '',
    );
  }

  TimetableConfig copyWith({
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    String? periodTimeSetId,
  }) {
    return TimetableConfig(
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: normalizeTimetableWeeks(totalWeeks ?? this.totalWeeks),
      periodTimeSetId: periodTimeSetId ?? this.periodTimeSetId,
    );
  }
}

class TimetableData {
  const TimetableData({
    required this.id,
    required this.config,
    required this.courses,
  });

  final String id;
  final TimetableConfig config;
  final List<CourseItem> courses;

  Map<String, dynamic> toJson() => {
    'id': id,
    'config': config.toJson(),
    'courses': courses.map((item) => item.toJson()).toList(),
  };

  factory TimetableData.fromJson(
    Map<String, dynamic> json, {
    String localeCode = defaultLocaleCode,
  }) {
    return TimetableData(
      id: json['id'] as String? ?? '',
      config: TimetableConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map? ?? const {}),
        localeCode: localeCode,
      ),
      courses: (json['courses'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) =>
                CourseItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory TimetableData.decode(String source) {
    return TimetableData.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  TimetableData copyWith({
    String? id,
    TimetableConfig? config,
    List<CourseItem>? courses,
  }) {
    return TimetableData(
      id: id ?? this.id,
      config: config ?? this.config,
      courses: courses ?? this.courses,
    );
  }
}

class TimetableLiveCourseTarget {
  const TimetableLiveCourseTarget({
    required this.week,
    required this.weekday,
    required this.courseId,
    required this.isCurrentCourse,
  });

  final int week;
  final int weekday;
  final String courseId;
  final bool isCurrentCourse;
}

List<CoursePeriodTime> _decodeLegacyPeriodTimes(Map<String, dynamic> json) {
  return (json['periodTimes'] as List<dynamic>? ?? const <dynamic>[])
      .map(
        (item) =>
            CoursePeriodTime.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
}

int _decodeLegacyDailyPeriods(
  Map<String, dynamic> json,
  List<CoursePeriodTime> legacyPeriodTimes,
) {
  return ((json['dailyPeriods'] as num?)?.toInt() ??
          (legacyPeriodTimes.isEmpty ? 10 : legacyPeriodTimes.length))
      .clamp(1, 999);
}

class TimetableExportData {
  const TimetableExportData({
    required this.timetables,
    required this.periodTimeSets,
  });

  final List<TimetableData> timetables;
  final List<PeriodTimeSet> periodTimeSets;

  TimetableData get timetable => timetables.first;

  Map<String, dynamic> toJson() => {
    'timetables': timetables.map((item) => item.toJson()).toList(),
    'periodTimeSets': periodTimeSets.map((item) => item.toJson()).toList(),
  };

  factory TimetableExportData.fromJson(
    Map<String, dynamic> json, {
    String localeCode = defaultLocaleCode,
  }) {
    if (json.containsKey('config') && json.containsKey('courses')) {
      final rawTimetable = Map<String, dynamic>.from(json);
      final rawConfig = Map<String, dynamic>.from(
        rawTimetable['config'] as Map? ?? const {},
      );
      final timetable = TimetableData.fromJson(
        rawTimetable,
        localeCode: localeCode,
      );
      final setId = timetable.config.periodTimeSetId.trim().isEmpty
          ? 'imported_period_times'
          : timetable.config.periodTimeSetId;
      final legacyPeriodTimes = _decodeLegacyPeriodTimes(rawConfig);
      final fallbackCount = _decodeLegacyDailyPeriods(
        rawConfig,
        legacyPeriodTimes,
      );
      final periodTimeSet = PeriodTimeSet(
        id: setId,
        name: importedPeriodTimeSetName(
          timetable.config.name,
          localeCode: localeCode,
        ),
        periodTimes: buildPeriodTimesForCount(
          legacyPeriodTimes.isEmpty ? fallbackCount : legacyPeriodTimes.length,
          source: legacyPeriodTimes,
        ),
      );
      return TimetableExportData(
        timetables: [
          timetable.copyWith(
            config: timetable.config.copyWith(periodTimeSetId: setId),
          ),
        ],
        periodTimeSets: [periodTimeSet],
      );
    }

    final timetables = json['timetables'] is List<dynamic>
        ? (json['timetables'] as List<dynamic>)
              .map(
                (item) => TimetableData.fromJson(
                  Map<String, dynamic>.from(item as Map),
                  localeCode: localeCode,
                ),
              )
              .toList()
        : [
            TimetableData.fromJson(
              Map<String, dynamic>.from(json['timetable'] as Map? ?? const {}),
              localeCode: localeCode,
            ),
          ];
    final periodTimeSets =
        (json['periodTimeSets'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) => PeriodTimeSet.fromJson(
                Map<String, dynamic>.from(item as Map),
                localeCode: localeCode,
              ),
            )
            .toList();
    return TimetableExportData(
      timetables: timetables,
      periodTimeSets: periodTimeSets,
    );
  }
}
