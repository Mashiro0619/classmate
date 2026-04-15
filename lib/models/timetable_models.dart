import 'dart:convert';

import 'package:flutter/material.dart';

const defaultPeriodTimesAssetPath = 'assets/default_period_times.json';
const defaultPeriodTimeSetId = 'period_set_default';
const defaultLocaleCode = 'zh';
const defaultThemeMode = 'system';
const defaultThemeSeedColorValue = 0xFF6750A4;
const defaultLiveCourseOutlineColorValue = 0xFFEF6C00;
const defaultLiveCourseOutlineEnabled = true;
const defaultLiveCourseOutlineFollowTheme = true;
const defaultLiveCourseOutlineCustomColorInitialized = false;
const maxTimetableWeeks = 100;
const currentPrivacyPolicyVersion = '2026-04-08';

bool _isEnglishLocale(String localeCode) =>
    normalizeLocaleCode(localeCode) == 'en';

Color deriveLiveCourseOutlineColorFromSeed(Color seedColor) {
  final hsl = HSLColor.fromColor(seedColor);
  final lightness = (hsl.lightness - 0.16).clamp(0.18, 0.72).toDouble();
  final saturation = (hsl.saturation + 0.08).clamp(0.12, 1.0).toDouble();
  return hsl.withLightness(lightness).withSaturation(saturation).toColor();
}

String defaultPeriodTimeSetName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'Default periods' : '默认节次';
}

String periodTimeSetFallbackName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'Period times' : '节次时间';
}

String untitledTimetableName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'Untitled timetable' : '未命名课表';
}

String newTimetableName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'New timetable' : '新课表';
}

String newPeriodTimeSetName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'New period time set' : '新节次时间';
}

String emptyTimetableName({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode) ? 'Empty timetable' : '空课表';
}

String importedPeriodTimeSetName(
  String timetableName, {
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? '$timetableName periods'
      : '$timetableName 节次';
}

String importFileTypeMismatchMessage({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode)
      ? 'Import file type does not match.'
      : '导入文件类型不匹配';
}

String importFileVersionUnsupportedMessage({
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? 'This import file version is not supported yet.'
      : '导入文件版本暂不支持';
}

String noPeriodTimesInImportMessage({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode)
      ? 'No period times found in the import file.'
      : '导入文件中没有节次时间';
}

String noPeriodTimeAvailableMessage({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode)
      ? 'No available period time set.'
      : '暂无可用节次时间';
}

String selectAtLeastOneTimetableMessage({
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? 'Please select at least one timetable.'
      : '请选择至少一个课表';
}

String noExportableTimetableMessage({String localeCode = defaultLocaleCode}) {
  return _isEnglishLocale(localeCode)
      ? 'There is no timetable available to export.'
      : '当前没有可导出的课表';
}

String replaceActiveRequiresSingleTimetableMessage({
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? 'Replacing the current timetable only supports selecting one timetable.'
      : '覆盖当前课表时只能选择一个课表';
}

String noActiveTimetableToReplaceMessage({
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? 'There is no current timetable to replace.'
      : '当前没有可覆盖的课表';
}

String periodTimeSetInUseMessage(
  int count, {
  String localeCode = defaultLocaleCode,
}) {
  return _isEnglishLocale(localeCode)
      ? 'This period time set is still used by $count timetable(s). Reassign them before deleting.'
      : '该节次时间仍被 $count 个课表使用，请先改关联再删除';
}

class CoursePeriodTime {
  const CoursePeriodTime({
    required this.index,
    required this.startMinutes,
    required this.endMinutes,
  });

  final int index;
  final int startMinutes;
  final int endMinutes;

  Map<String, dynamic> toJson() => {
    'index': index,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  factory CoursePeriodTime.fromJson(Map<String, dynamic> json) {
    return CoursePeriodTime(
      index: (json['index'] as num?)?.toInt() ?? 1,
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 8 * 60,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? (8 * 60) + 45,
    );
  }

  CoursePeriodTime copyWith({int? index, int? startMinutes, int? endMinutes}) {
    return CoursePeriodTime(
      index: index ?? this.index,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }
}

class PeriodTimeSet {
  const PeriodTimeSet({
    required this.id,
    required this.name,
    required this.periodTimes,
  });

  final String id;
  final String name;
  final List<CoursePeriodTime> periodTimes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'periodTimes': periodTimes.map((item) => item.toJson()).toList(),
  };

  factory PeriodTimeSet.fromJson(
    Map<String, dynamic> json, {
    String localeCode = defaultLocaleCode,
  }) {
    return PeriodTimeSet(
      id: json['id'] as String? ?? '',
      name:
          json['name'] as String? ??
          periodTimeSetFallbackName(localeCode: localeCode),
      periodTimes: (json['periodTimes'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (item) => CoursePeriodTime.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  PeriodTimeSet copyWith({
    String? id,
    String? name,
    List<CoursePeriodTime>? periodTimes,
  }) {
    return PeriodTimeSet(
      id: id ?? this.id,
      name: name ?? this.name,
      periodTimes: periodTimes ?? this.periodTimes,
    );
  }
}

class CourseItem {
  const CourseItem({
    required this.id,
    required this.name,
    required this.teacher,
    required this.location,
    required this.dayOfWeek,
    required this.semesterWeeks,
    required this.periods,
    required this.startMinutes,
    required this.endMinutes,
    required this.timeRange,
    required this.credit,
    required this.remarks,
    required this.customFields,
  });

  final String id;
  final String name;
  final String teacher;
  final String location;
  final int dayOfWeek;
  final List<int> semesterWeeks;
  final List<int> periods;
  final int startMinutes;
  final int endMinutes;
  final String timeRange;
  final double credit;
  final String remarks;
  final Map<String, dynamic> customFields;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'location': location,
    'dayOfWeek': normalizeDayOfWeek(dayOfWeek),
    'semesterWeeks': normalizeSemesterWeeks(semesterWeeks),
    'periods': periods,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'timeRange': timeRange,
    'credit': credit,
    'remarks': remarks,
    'customFields': customFields,
  };

  /// 兼容旧字段时只拿 weekday/weekdays 推 dayOfWeek，别顺手猜一套周次出来。
  factory CourseItem.fromJson(Map<String, dynamic> json) {
    final legacyDayOfWeek =
        (json['dayOfWeek'] as num?)?.toInt() ?? _decodeLegacyDayOfWeek(json);
    final semesterWeeks = json['semesterWeeks'] is List<dynamic>
        ? (json['semesterWeeks'] as List<dynamic>)
              .map((item) => (item as num).toInt())
              .toList()
        : const <int>[];
    return CourseItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      location: json['location'] as String? ?? '',
      dayOfWeek: normalizeDayOfWeek(legacyDayOfWeek),
      semesterWeeks: normalizeSemesterWeeks(semesterWeeks),
      periods: (json['periods'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => (item as num).toInt())
          .toList(),
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 8 * 60,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? (8 * 60) + 45,
      timeRange: json['timeRange'] as String? ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      remarks: json['remarks'] as String? ?? '',
      customFields: Map<String, dynamic>.from(
        json['customFields'] as Map? ?? const {},
      ),
    );
  }

  CourseItem copyWith({
    String? id,
    String? name,
    String? teacher,
    String? location,
    int? dayOfWeek,
    List<int>? semesterWeeks,
    List<int>? periods,
    int? startMinutes,
    int? endMinutes,
    String? timeRange,
    double? credit,
    String? remarks,
    Map<String, dynamic>? customFields,
  }) {
    return CourseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: normalizeDayOfWeek(dayOfWeek ?? this.dayOfWeek),
      semesterWeeks: normalizeSemesterWeeks(
        semesterWeeks ?? this.semesterWeeks,
      ),
      periods: periods ?? this.periods,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      timeRange: timeRange ?? this.timeRange,
      credit: credit ?? this.credit,
      remarks: remarks ?? this.remarks,
      customFields: customFields ?? this.customFields,
    );
  }
}

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
  });

  final int week;
  final int weekday;
  final String courseId;
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

class AppData {
  const AppData({
    required this.activeTimetableId,
    required this.timetables,
    required this.periodTimeSets,
    this.conflictDisplayCourseIds = const {},
    this.closeCoursePopupOnOutsideTap = true,
    this.preserveTimetableGaps = false,
    this.showPastEndedCourses = false,
    this.showFutureCourses = true,
    this.showTimetableGridLines = true,
    this.localeCode = defaultLocaleCode,
    this.themeMode = defaultThemeMode,
    this.themeSeedColorValue = defaultThemeSeedColorValue,
    this.liveCourseOutlineColorValue = defaultLiveCourseOutlineColorValue,
    this.liveCourseOutlineEnabled = defaultLiveCourseOutlineEnabled,
    this.liveCourseOutlineFollowTheme = defaultLiveCourseOutlineFollowTheme,
    this.liveCourseOutlineCustomColorInitialized =
        defaultLiveCourseOutlineCustomColorInitialized,
    this.privacyPolicyAcceptedVersion,
    this.privacyPolicyAcceptedAtIso,
    this.ignoredUpdateVersion,
    this.availableUpdateVersion,
  });

  final String activeTimetableId;
  final List<TimetableData> timetables;
  final List<PeriodTimeSet> periodTimeSets;
  final Map<String, String> conflictDisplayCourseIds;
  final bool closeCoursePopupOnOutsideTap;
  final bool preserveTimetableGaps;
  final bool showPastEndedCourses;
  final bool showFutureCourses;
  final bool showTimetableGridLines;
  final String localeCode;
  final String themeMode;
  final int themeSeedColorValue;
  final int liveCourseOutlineColorValue;
  final bool liveCourseOutlineEnabled;
  final bool liveCourseOutlineFollowTheme;
  final bool liveCourseOutlineCustomColorInitialized;
  final String? privacyPolicyAcceptedVersion;
  final String? privacyPolicyAcceptedAtIso;
  final String? ignoredUpdateVersion;
  final String? availableUpdateVersion;

  Map<String, dynamic> toJson() => {
    'activeTimetableId': activeTimetableId,
    'timetables': timetables.map((item) => item.toJson()).toList(),
    'periodTimeSets': periodTimeSets.map((item) => item.toJson()).toList(),
    'conflictDisplayCourseIds': conflictDisplayCourseIds,
    'closeCoursePopupOnOutsideTap': closeCoursePopupOnOutsideTap,
    'preserveTimetableGaps': preserveTimetableGaps,
    'showPastEndedCourses': showPastEndedCourses,
    'showFutureCourses': showFutureCourses,
    'showTimetableGridLines': showTimetableGridLines,
    'localeCode': normalizeLocaleCode(localeCode),
    'themeMode': normalizeThemeMode(themeMode),
    'themeSeedColorValue': themeSeedColorValue,
    'liveCourseOutlineColorValue': liveCourseOutlineColorValue,
    'liveCourseOutlineEnabled': liveCourseOutlineEnabled,
    'liveCourseOutlineFollowTheme': liveCourseOutlineFollowTheme,
    'liveCourseOutlineCustomColorInitialized':
        liveCourseOutlineCustomColorInitialized,
    'privacyPolicyAcceptedVersion': privacyPolicyAcceptedVersion,
    'privacyPolicyAcceptedAtIso': privacyPolicyAcceptedAtIso,
    'ignoredUpdateVersion': ignoredUpdateVersion,
    'availableUpdateVersion': availableUpdateVersion,
  };

  factory AppData.fromJson(Map<String, dynamic> json) {
    final localeCode = normalizeLocaleCode(
      json['localeCode'] as String? ?? defaultLocaleCode,
    );
    final rawTimetables =
        (json['timetables'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    final periodTimeSets =
        (json['periodTimeSets'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) => PeriodTimeSet.fromJson(
                Map<String, dynamic>.from(item as Map),
                localeCode: localeCode,
              ),
            )
            .toList();
    final normalizedSets = <PeriodTimeSet>[
      for (final item in periodTimeSets)
        _normalizePeriodTimeSet(item, localeCode: localeCode),
    ];
    final setIds = normalizedSets
        .map((item) => item.id)
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    final timetables = <TimetableData>[];

    for (final rawTimetable in rawTimetables) {
      final rawConfig = Map<String, dynamic>.from(
        rawTimetable['config'] as Map? ?? const {},
      );
      var timetable = TimetableData.fromJson(
        rawTimetable,
        localeCode: localeCode,
      );
      var periodTimeSetId = timetable.config.periodTimeSetId.trim();
      if (periodTimeSetId.isEmpty || !setIds.contains(periodTimeSetId)) {
        periodTimeSetId = _nextGeneratedPeriodTimeSetId(setIds);
        final legacyPeriodTimes = _decodeLegacyPeriodTimes(rawConfig);
        final fallbackCount = _decodeLegacyDailyPeriods(
          rawConfig,
          legacyPeriodTimes,
        );
        normalizedSets.add(
          PeriodTimeSet(
            id: periodTimeSetId,
            name: importedPeriodTimeSetName(
              timetable.config.name,
              localeCode: localeCode,
            ),
            periodTimes: buildPeriodTimesForCount(
              legacyPeriodTimes.isEmpty
                  ? fallbackCount
                  : legacyPeriodTimes.length,
              source: legacyPeriodTimes,
            ),
          ),
        );
        setIds.add(periodTimeSetId);
      }
      timetable = timetable.copyWith(
        config: timetable.config.copyWith(periodTimeSetId: periodTimeSetId),
      );
      timetables.add(timetable);
    }

    final activeTimetableId =
        timetables.any((item) => item.id == json['activeTimetableId'])
        ? json['activeTimetableId'] as String
        : timetables.isEmpty
        ? ''
        : timetables.first.id;
    return AppData(
      activeTimetableId: activeTimetableId,
      timetables: timetables,
      periodTimeSets: normalizedSets,
      conflictDisplayCourseIds: Map<String, String>.from(
        json['conflictDisplayCourseIds'] as Map? ?? const {},
      ),
      closeCoursePopupOnOutsideTap:
          json['closeCoursePopupOnOutsideTap'] as bool? ?? true,
      preserveTimetableGaps: json['preserveTimetableGaps'] as bool? ?? false,
      showPastEndedCourses: json['showPastEndedCourses'] as bool? ?? false,
      showFutureCourses: json['showFutureCourses'] as bool? ?? true,
      showTimetableGridLines:
          json['showTimetableGridLines'] as bool? ?? true,
      localeCode: localeCode,
      themeMode: normalizeThemeMode(
        json['themeMode'] as String? ?? defaultThemeMode,
      ),
      themeSeedColorValue:
          (json['themeSeedColorValue'] as num?)?.toInt() ??
          defaultThemeSeedColorValue,
      liveCourseOutlineColorValue:
          (json['liveCourseOutlineColorValue'] as num?)?.toInt() ??
          defaultLiveCourseOutlineColorValue,
      liveCourseOutlineEnabled:
          json['liveCourseOutlineEnabled'] as bool? ??
          defaultLiveCourseOutlineEnabled,
      liveCourseOutlineFollowTheme:
          json['liveCourseOutlineFollowTheme'] as bool? ??
          defaultLiveCourseOutlineFollowTheme,
      liveCourseOutlineCustomColorInitialized:
          json['liveCourseOutlineCustomColorInitialized'] as bool? ??
          defaultLiveCourseOutlineCustomColorInitialized,
      privacyPolicyAcceptedVersion:
          json['privacyPolicyAcceptedVersion'] as String?,
      privacyPolicyAcceptedAtIso: json['privacyPolicyAcceptedAtIso'] as String?,
      ignoredUpdateVersion: json['ignoredUpdateVersion'] as String?,
      availableUpdateVersion: json['availableUpdateVersion'] as String?,
    );
  }

  AppData copyWith({
    String? activeTimetableId,
    List<TimetableData>? timetables,
    List<PeriodTimeSet>? periodTimeSets,
    Map<String, String>? conflictDisplayCourseIds,
    bool? closeCoursePopupOnOutsideTap,
    bool? preserveTimetableGaps,
    bool? showPastEndedCourses,
    bool? showFutureCourses,
    bool? showTimetableGridLines,
    String? localeCode,
    String? themeMode,
    int? themeSeedColorValue,
    int? liveCourseOutlineColorValue,
    bool? liveCourseOutlineEnabled,
    bool? liveCourseOutlineFollowTheme,
    bool? liveCourseOutlineCustomColorInitialized,
    String? privacyPolicyAcceptedVersion,
    String? privacyPolicyAcceptedAtIso,
    String? ignoredUpdateVersion,
    String? availableUpdateVersion,
  }) {
    return AppData(
      activeTimetableId: activeTimetableId ?? this.activeTimetableId,
      timetables: timetables ?? this.timetables,
      periodTimeSets: periodTimeSets ?? this.periodTimeSets,
      conflictDisplayCourseIds:
          conflictDisplayCourseIds ?? this.conflictDisplayCourseIds,
      closeCoursePopupOnOutsideTap:
          closeCoursePopupOnOutsideTap ?? this.closeCoursePopupOnOutsideTap,
      preserveTimetableGaps:
          preserveTimetableGaps ?? this.preserveTimetableGaps,
      showPastEndedCourses:
          showPastEndedCourses ?? this.showPastEndedCourses,
      showFutureCourses:
          showFutureCourses ?? this.showFutureCourses,
      showTimetableGridLines:
          showTimetableGridLines ?? this.showTimetableGridLines,
      localeCode: normalizeLocaleCode(localeCode ?? this.localeCode),
      themeMode: normalizeThemeMode(themeMode ?? this.themeMode),
      themeSeedColorValue: themeSeedColorValue ?? this.themeSeedColorValue,
      liveCourseOutlineColorValue:
          liveCourseOutlineColorValue ?? this.liveCourseOutlineColorValue,
      liveCourseOutlineEnabled:
          liveCourseOutlineEnabled ?? this.liveCourseOutlineEnabled,
      liveCourseOutlineFollowTheme:
          liveCourseOutlineFollowTheme ?? this.liveCourseOutlineFollowTheme,
      liveCourseOutlineCustomColorInitialized:
          liveCourseOutlineCustomColorInitialized ??
          this.liveCourseOutlineCustomColorInitialized,
      privacyPolicyAcceptedVersion:
          privacyPolicyAcceptedVersion ?? this.privacyPolicyAcceptedVersion,
      privacyPolicyAcceptedAtIso:
          privacyPolicyAcceptedAtIso ?? this.privacyPolicyAcceptedAtIso,
      ignoredUpdateVersion:
          ignoredUpdateVersion ?? this.ignoredUpdateVersion,
      availableUpdateVersion:
          availableUpdateVersion ?? this.availableUpdateVersion,
    );
  }

  String encode() => jsonEncode(toJson());

  factory AppData.decode(String source) {
    return AppData.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}

class ImportExportEnvelope {
  const ImportExportEnvelope({
    required this.schema,
    required this.version,
    required this.data,
  });

  final String schema;
  final int version;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'data': data,
  };

  factory ImportExportEnvelope.fromJson(Map<String, dynamic> json) {
    return ImportExportEnvelope(
      schema: json['schema'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  String encode() => jsonEncode(toJson());

  factory ImportExportEnvelope.decode(String source) {
    return ImportExportEnvelope.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}

const importExportVersion = 2;
const appDataSchema = 'classmate-app-data';
const timetableDataSchema = 'classmate-timetable-data';
const periodTimesSchema = 'classmate-period-times';

String encodeAppDataEnvelope(AppData data) {
  return ImportExportEnvelope(
    schema: appDataSchema,
    version: importExportVersion,
    data: data.toJson(),
  ).encode();
}

String encodeTimetableDataEnvelope(TimetableExportData data) {
  return ImportExportEnvelope(
    schema: timetableDataSchema,
    version: importExportVersion,
    data: data.toJson(),
  ).encode();
}

String encodePeriodTimesEnvelope(List<CoursePeriodTime> periodTimes) {
  return ImportExportEnvelope(
    schema: periodTimesSchema,
    version: importExportVersion,
    data: {'periodTimes': periodTimes.map((item) => item.toJson()).toList()},
  ).encode();
}

List<CoursePeriodTime> decodePeriodTimesEnvelope(
  String source, {
  String localeCode = defaultLocaleCode,
}) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(
    envelope,
    expectedSchema: periodTimesSchema,
    localeCode: localeCode,
  );
  return (envelope.data['periodTimes'] as List<dynamic>? ?? const <dynamic>[])
      .map(
        (item) =>
            CoursePeriodTime.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
}

AppData decodeAppDataEnvelope(
  String source, {
  String localeCode = defaultLocaleCode,
}) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(
    envelope,
    expectedSchema: appDataSchema,
    localeCode: localeCode,
  );
  return AppData.fromJson({...envelope.data, 'localeCode': localeCode});
}

TimetableExportData decodeTimetableDataEnvelope(
  String source, {
  String localeCode = defaultLocaleCode,
}) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(
    envelope,
    expectedSchema: timetableDataSchema,
    localeCode: localeCode,
  );
  return TimetableExportData.fromJson(envelope.data, localeCode: localeCode);
}

void _ensureSupportedEnvelope(
  ImportExportEnvelope envelope, {
  required String expectedSchema,
  String localeCode = defaultLocaleCode,
}) {
  if (envelope.schema != expectedSchema) {
    throw FormatException(
      importFileTypeMismatchMessage(localeCode: localeCode),
    );
  }
  if (envelope.version > importExportVersion) {
    throw FormatException(
      importFileVersionUnsupportedMessage(localeCode: localeCode),
    );
  }
}

List<CoursePeriodTime> buildDefaultPeriodTimes() {
  const slots = <List<int>>[
    [8, 0, 8, 45],
    [8, 55, 9, 40],
    [10, 0, 10, 45],
    [10, 55, 11, 40],
    [14, 0, 14, 45],
    [14, 55, 15, 40],
    [16, 0, 16, 45],
    [16, 55, 17, 40],
    [19, 0, 19, 45],
    [19, 55, 20, 40],
    [20, 50, 21, 35],
    [21, 40, 22, 25],
  ];

  return List.generate(slots.length, (index) {
    final slot = slots[index];
    return CoursePeriodTime(
      index: index + 1,
      startMinutes: slot[0] * 60 + slot[1],
      endMinutes: slot[2] * 60 + slot[3],
    );
  });
}

List<CoursePeriodTime> buildPeriodTimesForCount(
  int count, {
  List<CoursePeriodTime>? source,
}) {
  final safeCount = count < 1 ? 1 : count;
  final defaults = buildDefaultPeriodTimes();
  final seed = (source == null || source.isEmpty)
      ? <CoursePeriodTime>[]
      : List.generate(
          source.length,
          (index) => source[index].copyWith(index: index + 1),
        );
  final result = <CoursePeriodTime>[];

  for (var index = 0; index < safeCount; index++) {
    if (index < seed.length) {
      result.add(seed[index].copyWith(index: index + 1));
      continue;
    }
    if (index < defaults.length) {
      result.add(defaults[index].copyWith(index: index + 1));
      continue;
    }
    result.add(_buildNextPeriodTime(result, index + 1));
  }

  return result;
}

CoursePeriodTime _buildNextPeriodTime(
  List<CoursePeriodTime> existing,
  int index,
) {
  if (existing.isEmpty) {
    return const CoursePeriodTime(
      index: 1,
      startMinutes: 8 * 60,
      endMinutes: (8 * 60) + 45,
    );
  }
  final last = existing.last;
  final previous = existing.length > 1 ? existing[existing.length - 2] : null;
  final duration = last.endMinutes > last.startMinutes
      ? last.endMinutes - last.startMinutes
      : 45;
  final gap = previous == null
      ? 10
      : (last.startMinutes - previous.endMinutes).clamp(0, 120);
  final startMinutes = last.endMinutes + gap;
  return CoursePeriodTime(
    index: index,
    startMinutes: startMinutes,
    endMinutes: startMinutes + duration,
  );
}

String formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

int normalizeTimetableWeeks(int? totalWeeks) {
  return (totalWeeks ?? 18).clamp(1, maxTimetableWeeks);
}

DateTime normalizeDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime startOfWeekMonday(DateTime date) {
  final normalized = normalizeDateOnly(date);
  return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
}

String buildTimeRange(int startMinutes, int endMinutes) {
  return '${formatMinutes(startMinutes)} - ${formatMinutes(endMinutes)}';
}

int normalizeDayOfWeek(int? dayOfWeek) {
  final value = dayOfWeek ?? 1;
  return value.clamp(1, 7);
}

String normalizeLocaleCode(String? localeCode) {
  return localeCode == 'en' ? 'en' : defaultLocaleCode;
}

String normalizeThemeMode(String? themeMode) {
  switch (themeMode) {
    case 'dark':
      return 'dark';
    case 'system':
      return 'system';
    case 'light':
      return 'light';
    default:
      return defaultThemeMode;
  }
}

/// 这里保留空列表语义，后面会把它当成“整学期都生效”，不用强行补满所有周。
List<int> normalizeSemesterWeeks(List<int> semesterWeeks) {
  final normalized = semesterWeeks.where((week) => week > 0).toSet().toList()
    ..sort();
  return normalized;
}

List<int> buildAllSemesterWeeks(int totalWeeks) {
  final safeTotalWeeks = normalizeTimetableWeeks(totalWeeks);
  return List.generate(safeTotalWeeks, (index) => index + 1);
}

bool matchesSemesterWeek(CourseItem course, int selectedWeek) {
  return course.semesterWeeks.isEmpty ||
      course.semesterWeeks.contains(selectedWeek);
}

String formatDayOfWeekLabel(
  int dayOfWeek, {
  String localeCode = defaultLocaleCode,
}) {
  final normalizedDay = normalizeDayOfWeek(dayOfWeek);
  if (normalizeLocaleCode(localeCode) == 'en') {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels[normalizedDay - 1];
  }
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return '星期${labels[normalizedDay - 1]}';
}

String formatWeekdayShortLabel(
  int dayOfWeek, {
  String localeCode = defaultLocaleCode,
}) {
  final normalizedDay = normalizeDayOfWeek(dayOfWeek);
  if (normalizeLocaleCode(localeCode) == 'en') {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[normalizedDay - 1];
  }
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[normalizedDay - 1];
}

String formatMonthLabel(int month, {String localeCode = defaultLocaleCode}) {
  final normalizedMonth = month.clamp(1, 12);
  if (normalizeLocaleCode(localeCode) == 'en') {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[normalizedMonth - 1];
  }
  return '$normalizedMonth月';
}

String formatSemesterWeeksLabel(
  List<int> semesterWeeks, {
  int? totalWeeks,
  String localeCode = defaultLocaleCode,
}) {
  final normalized = normalizeSemesterWeeks(semesterWeeks);
  final isEnglish = normalizeLocaleCode(localeCode) == 'en';
  if (normalized.isEmpty) {
    if (totalWeeks == null) {
      return isEnglish ? 'All semester' : '全学期';
    }
    return isEnglish ? 'Weeks 1-$totalWeeks' : '第 1-$totalWeeks 周';
  }
  final ranges = <String>[];
  var start = normalized.first;
  var previous = normalized.first;
  for (final week in normalized.skip(1)) {
    if (week == previous + 1) {
      previous = week;
      continue;
    }
    ranges.add(start == previous ? '$start' : '$start-$previous');
    start = previous = week;
  }
  ranges.add(start == previous ? '$start' : '$start-$previous');
  return isEnglish ? 'Weeks ${ranges.join(', ')}' : '第 ${ranges.join('、')} 周';
}

/// 只有时间段能和连续节次严丝合缝对上时才回填节次；对不上就宁可不显示。
List<int> matchPeriodsForTimeRange(
  List<CoursePeriodTime> periodTimes,
  int startMinutes,
  int endMinutes,
) {
  if (periodTimes.isEmpty || startMinutes >= endMinutes) {
    return const [];
  }
  for (var startIndex = 0; startIndex < periodTimes.length; startIndex++) {
    if (periodTimes[startIndex].startMinutes != startMinutes) {
      continue;
    }
    var currentEnd = periodTimes[startIndex].endMinutes;
    final periods = <int>[periodTimes[startIndex].index];
    if (currentEnd == endMinutes) {
      return periods;
    }
    for (
      var endIndex = startIndex + 1;
      endIndex < periodTimes.length;
      endIndex++
    ) {
      currentEnd = periodTimes[endIndex].endMinutes;
      periods.add(periodTimes[endIndex].index);
      if (currentEnd == endMinutes) {
        return periods;
      }
    }
  }
  return const [];
}

int _decodeLegacyDayOfWeek(Map<String, dynamic> json) {
  if (json['weekday'] is int) {
    return json['weekday'] as int;
  }
  if (json['weekdays'] is List<dynamic> &&
      (json['weekdays'] as List<dynamic>).isNotEmpty) {
    return ((json['weekdays'] as List<dynamic>).first as num).toInt();
  }
  return 1;
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

PeriodTimeSet _normalizePeriodTimeSet(
  PeriodTimeSet periodTimeSet, {
  String localeCode = defaultLocaleCode,
}) {
  final normalizedTimes = buildPeriodTimesForCount(
    periodTimeSet.periodTimes.isEmpty ? 1 : periodTimeSet.periodTimes.length,
    source: periodTimeSet.periodTimes,
  );
  return periodTimeSet.copyWith(
    name: periodTimeSet.name.trim().isEmpty
        ? periodTimeSetFallbackName(localeCode: localeCode)
        : periodTimeSet.name.trim(),
    periodTimes: normalizedTimes,
  );
}

String _nextGeneratedPeriodTimeSetId(Set<String> existingIds) {
  var stamp = DateTime.now().microsecondsSinceEpoch;
  var candidate = 'period_set_$stamp';
  while (existingIds.contains(candidate)) {
    stamp += 1;
    candidate = 'period_set_$stamp';
  }
  return candidate;
}

int currentWeekFor(TimetableConfig config, {DateTime? now}) {
  final today = startOfWeekMonday(now ?? DateTime.now());
  final semesterWeekStart = startOfWeekMonday(config.startDate);
  final days = today.difference(semesterWeekStart).inDays;
  if (days < 0) {
    return 1;
  }
  final week = (days ~/ 7) + 1;
  if (week > config.totalWeeks) {
    return config.totalWeeks;
  }
  return week;
}

DateTime startOfWeekFor(TimetableConfig config, int week) {
  return startOfWeekMonday(
    normalizeDateOnly(config.startDate).add(Duration(days: (week - 1) * 7)),
  );
}

TimetableLiveCourseTarget? currentOrNextCourseTargetFor({
  required TimetableData timetable,
  required int selectedWeek,
  required int realCurrentWeek,
  required DateTime now,
  String? Function(String conflictKey)? displayedCourseIdForConflict,
}) {
  final today = normalizeDateOnly(now);
  final weekday = normalizeDayOfWeek(today.weekday);
  final nowMinutes = (now.hour * 60) + now.minute;
  final todayTarget = _courseTargetForDay(
    timetable: timetable,
    targetWeek: realCurrentWeek,
    weekday: weekday,
    displayedCourseIdForConflict: displayedCourseIdForConflict,
    nowMinutes: nowMinutes,
  );
  if (todayTarget != null) {
    return todayTarget.week == selectedWeek ? todayTarget : null;
  }

  final tomorrow = today.add(const Duration(days: 1));
  if (!_isDateWithinTimetableRange(timetable.config, tomorrow)) {
    return null;
  }
  final tomorrowWeek = currentWeekFor(timetable.config, now: tomorrow);
  final tomorrowWeekday = normalizeDayOfWeek(tomorrow.weekday);
  final tomorrowTarget = _courseTargetForDay(
    timetable: timetable,
    targetWeek: tomorrowWeek,
    weekday: tomorrowWeekday,
    displayedCourseIdForConflict: displayedCourseIdForConflict,
  );
  if (tomorrowTarget == null) {
    return null;
  }
  return tomorrowTarget.week == selectedWeek ? tomorrowTarget : null;
}

TimetableLiveCourseTarget? _courseTargetForDay({
  required TimetableData timetable,
  required int targetWeek,
  required int weekday,
  required String? Function(String conflictKey)? displayedCourseIdForConflict,
  int? nowMinutes,
}) {
  final dayCourses = timetable.courses
      .where(
        (course) =>
            course.dayOfWeek == weekday && matchesSemesterWeek(course, targetWeek),
      )
      .toList()
    ..sort(_compareCoursesByStart);
  if (dayCourses.isEmpty) {
    return null;
  }

  if (nowMinutes != null) {
    final currentCourses = dayCourses
        .where(
          (course) =>
              course.startMinutes <= nowMinutes && nowMinutes < course.endMinutes,
        )
        .toList();
    if (currentCourses.isNotEmpty) {
      return TimetableLiveCourseTarget(
        week: targetWeek,
        weekday: weekday,
        courseId: _resolveDisplayedCourseId(
          timetable.id,
          weekday,
          currentCourses,
          displayedCourseIdForConflict,
        ),
      );
    }

    final nextStartMinutes = dayCourses
        .where((course) => course.startMinutes > nowMinutes)
        .map((course) => course.startMinutes)
        .fold<int?>(
          null,
          (best, value) => best == null || value < best ? value : best,
        );
    if (nextStartMinutes != null) {
      final nextCourses = dayCourses
          .where((course) => course.startMinutes == nextStartMinutes)
          .toList();
      if (nextCourses.isNotEmpty) {
        return TimetableLiveCourseTarget(
          week: targetWeek,
          weekday: weekday,
          courseId: _resolveDisplayedCourseId(
            timetable.id,
            weekday,
            nextCourses,
            displayedCourseIdForConflict,
          ),
        );
      }
    }
    return null;
  }

  final firstStartMinutes = dayCourses.first.startMinutes;
  final firstCourses = dayCourses
      .where((course) => course.startMinutes == firstStartMinutes)
      .toList();
  return TimetableLiveCourseTarget(
    week: targetWeek,
    weekday: weekday,
    courseId: _resolveDisplayedCourseId(
      timetable.id,
      weekday,
      firstCourses,
      displayedCourseIdForConflict,
    ),
  );
}

bool _isDateWithinTimetableRange(TimetableConfig config, DateTime date) {
  final normalizedDate = normalizeDateOnly(date);
  final lastWeekStart = startOfWeekFor(config, config.totalWeeks);
  final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
  return !normalizedDate.isAfter(lastWeekEnd);
}

String _resolveDisplayedCourseId(
  String timetableId,
  int weekday,
  List<CourseItem> courses,
  String? Function(String conflictKey)? displayedCourseIdForConflict,
) {
  final sortedCourses = [...courses]..sort(_compareCoursesByStart);
  if (isFullConflictGroup(sortedCourses)) {
    final conflictKey = buildConflictKeyForCourses(
      timetableId,
      weekday,
      sortedCourses,
    );
    return pickDisplayedCourseForConflict(
      sortedCourses,
      displayedCourseIdForConflict?.call(conflictKey),
    ).id;
  }
  final prioritizedCourses = [...sortedCourses]..sort(compareCoursePaintPriority);
  return prioritizedCourses.first.id;
}

int _compareCoursesByStart(CourseItem a, CourseItem b) {
  final startCompare = a.startMinutes.compareTo(b.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  final endCompare = a.endMinutes.compareTo(b.endMinutes);
  if (endCompare != 0) {
    return endCompare;
  }
  return a.id.compareTo(b.id);
}

bool isFullConflictGroup(List<CourseItem> courses) {
  if (courses.length < 2) {
    return false;
  }
  final first = courses.first;
  final allSameRange = courses.every(
    (item) =>
        item.startMinutes == first.startMinutes &&
        item.endMinutes == first.endMinutes,
  );
  if (allSameRange) {
    return true;
  }
  if (courses.length == 2) {
    return _courseContains(courses[0], courses[1]) ||
        _courseContains(courses[1], courses[0]);
  }
  return false;
}

bool _courseContains(CourseItem outer, CourseItem inner) {
  return outer.startMinutes <= inner.startMinutes &&
      outer.endMinutes >= inner.endMinutes;
}

CourseItem pickDisplayedCourseForConflict(
  List<CourseItem> courses,
  String? displayedCourseId,
) {
  for (final course in courses) {
    if (course.id == displayedCourseId) {
      return course;
    }
  }
  final sorted = [...courses]..sort(_compareDisplayedCourseChoice);
  return sorted.first;
}

int _compareDisplayedCourseChoice(CourseItem a, CourseItem b) {
  final durationCompare = (b.endMinutes - b.startMinutes).compareTo(
    a.endMinutes - a.startMinutes,
  );
  if (durationCompare != 0) {
    return durationCompare;
  }
  final startCompare = b.startMinutes.compareTo(a.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  return a.id.compareTo(b.id);
}

String buildConflictKeyForCourses(
  String timetableId,
  int weekday,
  List<CourseItem> courses,
) {
  final courseIds = courses.map((item) => item.id).toList()..sort();
  final startMinutes = courses
      .map((item) => item.startMinutes)
      .reduce((a, b) => a < b ? a : b);
  final endMinutes = courses
      .map((item) => item.endMinutes)
      .reduce((a, b) => a > b ? a : b);
  return '$timetableId|$weekday|$startMinutes|$endMinutes|${courseIds.join(',')}';
}

int compareCoursePaintPriority(CourseItem a, CourseItem b) {
  final startCompare = a.startMinutes.compareTo(b.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  final durationCompare = (b.endMinutes - b.startMinutes).compareTo(
    a.endMinutes - a.startMinutes,
  );
  if (durationCompare != 0) {
    return durationCompare;
  }
  return a.id.compareTo(b.id);
}

AppData buildInitialAppData(
  List<CoursePeriodTime> periodTimes, {
  String localeCode = defaultLocaleCode,
}) {
  final defaultSet = PeriodTimeSet(
    id: defaultPeriodTimeSetId,
    name: defaultPeriodTimeSetName(localeCode: localeCode),
    periodTimes: buildPeriodTimesForCount(
      periodTimes.isEmpty ? 1 : periodTimes.length,
      source: periodTimes,
    ),
  );

  return AppData(
    activeTimetableId: '',
    timetables: const [],
    periodTimeSets: [defaultSet],
    localeCode: localeCode,
  );
}
