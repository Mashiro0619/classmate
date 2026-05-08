import 'dart:convert';

import '../l10n/app_locale.dart';
import '../utils/constants.dart';
import '../utils/localized_names.dart';
import '../utils/time_utils.dart';
import 'course_item.dart';
import 'timetable_data.dart';

const Symbol _keepNullable = #keep;

class SchoolImportParserSettings {
  const SchoolImportParserSettings({
    this.source = defaultSchoolImportParserSource,
    this.customBaseUrl = '',
    this.customApiKey = '',
    this.customModel = '',
    this.customPrompt = '',
  });

  final String source;
  final String customBaseUrl;
  final String customApiKey;
  final String customModel;
  final String customPrompt;

  Map<String, dynamic> toJson() => {
    'source': normalizeSchoolImportParserSource(source),
    'customBaseUrl': customBaseUrl.trim(),
    'customApiKey': customApiKey.trim(),
    'customModel': customModel.trim(),
    'customPrompt': customPrompt.trim(),
  };

  factory SchoolImportParserSettings.fromJson(Map<String, dynamic> json) {
    return SchoolImportParserSettings(
      source: normalizeSchoolImportParserSource(json['source'] as String?),
      customBaseUrl: (json['customBaseUrl'] as String? ?? '').trim(),
      customApiKey: (json['customApiKey'] as String? ?? '').trim(),
      customModel: (json['customModel'] as String? ?? '').trim(),
      customPrompt: (json['customPrompt'] as String? ?? '').trim(),
    );
  }

  SchoolImportParserSettings copyWith({
    String? source,
    String? customBaseUrl,
    String? customApiKey,
    String? customModel,
    String? customPrompt,
  }) {
    return SchoolImportParserSettings(
      source: normalizeSchoolImportParserSource(source ?? this.source),
      customBaseUrl: (customBaseUrl ?? this.customBaseUrl).trim(),
      customApiKey: (customApiKey ?? this.customApiKey).trim(),
      customModel: (customModel ?? this.customModel).trim(),
      customPrompt: (customPrompt ?? this.customPrompt).trim(),
    );
  }
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
    this.themeColorMode = defaultThemeColorMode,
    this.themeSeedColorValue = defaultThemeSeedColorValue,
    this.colorfulCourseTextColorMode = defaultColorfulCourseTextColorMode,
    this.colorfulUiColorValues = const {},
    this.courseNameColorValues = const {},
    this.schoolImportParserSettings = const SchoolImportParserSettings(),
    this.liveCourseOutlineColorValue = defaultLiveCourseOutlineColorValue,
    this.liveCourseOutlineEnabled = defaultLiveCourseOutlineEnabled,
    this.liveCourseOutlineFollowTheme = defaultLiveCourseOutlineFollowTheme,
    this.liveCourseOutlineCustomColorInitialized =
        defaultLiveCourseOutlineCustomColorInitialized,
    this.liveCourseOutlineMode = defaultLiveCourseOutlineMode,
    this.liveCourseOutlineWidth = defaultLiveCourseOutlineWidth,
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
  final String themeColorMode;
  final int themeSeedColorValue;
  final String colorfulCourseTextColorMode;
  final Map<String, int> colorfulUiColorValues;
  final Map<String, int> courseNameColorValues;
  final SchoolImportParserSettings schoolImportParserSettings;
  final int liveCourseOutlineColorValue;
  final bool liveCourseOutlineEnabled;
  final bool liveCourseOutlineFollowTheme;
  final bool liveCourseOutlineCustomColorInitialized;
  final String liveCourseOutlineMode;
  final double liveCourseOutlineWidth;
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
    'themeColorMode': normalizeThemeColorMode(themeColorMode),
    'themeSeedColorValue': themeSeedColorValue,
    'colorfulCourseTextColorMode': normalizeColorfulCourseTextColorMode(
      colorfulCourseTextColorMode,
    ),
    'colorfulUiColorValues': colorfulUiColorValues,
    'courseNameColorValues': courseNameColorValues,
    'schoolImportParserSettings': schoolImportParserSettings.toJson(),
    'liveCourseOutlineColorValue': liveCourseOutlineColorValue,
    'liveCourseOutlineEnabled': liveCourseOutlineEnabled,
    'liveCourseOutlineFollowTheme': liveCourseOutlineFollowTheme,
    'liveCourseOutlineCustomColorInitialized':
        liveCourseOutlineCustomColorInitialized,
    'liveCourseOutlineMode': normalizeLiveCourseOutlineMode(
      liveCourseOutlineMode,
    ),
    'liveCourseOutlineWidth': liveCourseOutlineWidth,
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
      themeColorMode: normalizeThemeColorMode(
        json['themeColorMode'] as String? ?? defaultThemeColorMode,
      ),
      themeSeedColorValue:
          (json['themeSeedColorValue'] as num?)?.toInt() ??
          defaultThemeSeedColorValue,
      colorfulCourseTextColorMode: normalizeColorfulCourseTextColorMode(
        json['colorfulCourseTextColorMode'] as String? ??
            defaultColorfulCourseTextColorMode,
      ),
      colorfulUiColorValues: decodeColorValueMap(
        json['colorfulUiColorValues'],
      ),
      courseNameColorValues: decodeColorValueMap(
        json['courseNameColorValues'],
      ),
      schoolImportParserSettings: SchoolImportParserSettings.fromJson(
        Map<String, dynamic>.from(
          json['schoolImportParserSettings'] as Map? ?? const {},
        ),
      ),
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
      liveCourseOutlineMode: normalizeLiveCourseOutlineMode(
        json['liveCourseOutlineMode'] as String? ?? defaultLiveCourseOutlineMode,
      ),
      liveCourseOutlineWidth: normalizeLiveCourseOutlineWidth(
        (json['liveCourseOutlineWidth'] as num?)?.toDouble(),
      ),
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
    String? themeColorMode,
    int? themeSeedColorValue,
    String? colorfulCourseTextColorMode,
    Map<String, int>? colorfulUiColorValues,
    Map<String, int>? courseNameColorValues,
    SchoolImportParserSettings? schoolImportParserSettings,
    int? liveCourseOutlineColorValue,
    bool? liveCourseOutlineEnabled,
    bool? liveCourseOutlineFollowTheme,
    bool? liveCourseOutlineCustomColorInitialized,
    String? liveCourseOutlineMode,
    double? liveCourseOutlineWidth,
    Object? privacyPolicyAcceptedVersion = _keepNullable,
    Object? privacyPolicyAcceptedAtIso = _keepNullable,
    Object? ignoredUpdateVersion = _keepNullable,
    Object? availableUpdateVersion = _keepNullable,
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
      themeColorMode: normalizeThemeColorMode(
        themeColorMode ?? this.themeColorMode,
      ),
      themeSeedColorValue: themeSeedColorValue ?? this.themeSeedColorValue,
      colorfulCourseTextColorMode: normalizeColorfulCourseTextColorMode(
        colorfulCourseTextColorMode ?? this.colorfulCourseTextColorMode,
      ),
      colorfulUiColorValues:
          colorfulUiColorValues ?? this.colorfulUiColorValues,
      courseNameColorValues:
          courseNameColorValues ?? this.courseNameColorValues,
      schoolImportParserSettings:
          schoolImportParserSettings ?? this.schoolImportParserSettings,
      liveCourseOutlineColorValue:
          liveCourseOutlineColorValue ?? this.liveCourseOutlineColorValue,
      liveCourseOutlineEnabled:
          liveCourseOutlineEnabled ?? this.liveCourseOutlineEnabled,
      liveCourseOutlineFollowTheme:
          liveCourseOutlineFollowTheme ?? this.liveCourseOutlineFollowTheme,
      liveCourseOutlineCustomColorInitialized:
          liveCourseOutlineCustomColorInitialized ??
          this.liveCourseOutlineCustomColorInitialized,
      liveCourseOutlineMode: normalizeLiveCourseOutlineMode(
        liveCourseOutlineMode ?? this.liveCourseOutlineMode,
      ),
      liveCourseOutlineWidth: normalizeLiveCourseOutlineWidth(
        liveCourseOutlineWidth ?? this.liveCourseOutlineWidth,
      ),
      privacyPolicyAcceptedVersion:
          identical(privacyPolicyAcceptedVersion, _keepNullable)
              ? this.privacyPolicyAcceptedVersion
              : privacyPolicyAcceptedVersion as String?,
      privacyPolicyAcceptedAtIso:
          identical(privacyPolicyAcceptedAtIso, _keepNullable)
              ? this.privacyPolicyAcceptedAtIso
              : privacyPolicyAcceptedAtIso as String?,
      ignoredUpdateVersion: identical(ignoredUpdateVersion, _keepNullable)
          ? this.ignoredUpdateVersion
          : ignoredUpdateVersion as String?,
      availableUpdateVersion:
          identical(availableUpdateVersion, _keepNullable)
              ? this.availableUpdateVersion
              : availableUpdateVersion as String?,
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

// Legacy decoders - reused within this file
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
