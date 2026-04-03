import 'dart:convert';

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
      index: json['index'] as int,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
    );
  }

  CoursePeriodTime copyWith({
    int? index,
    int? startMinutes,
    int? endMinutes,
  }) {
    return CoursePeriodTime(
      index: index ?? this.index,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
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

  /// 旧数据里的 weekday/weekdays 只视为“星期几”来源；周次范围缺失时默认留空，表示全学期有效。
  factory CourseItem.fromJson(Map<String, dynamic> json) {
    final legacyDayOfWeek = json['dayOfWeek'] as int? ?? _decodeLegacyDayOfWeek(json);
    final semesterWeeks = json['semesterWeeks'] is List<dynamic>
        ? (json['semesterWeeks'] as List<dynamic>).cast<int>()
        : const <int>[];
    return CourseItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      location: json['location'] as String? ?? '',
      dayOfWeek: normalizeDayOfWeek(legacyDayOfWeek),
      semesterWeeks: normalizeSemesterWeeks(semesterWeeks),
      periods: (json['periods'] as List<dynamic>? ?? const <dynamic>[]).cast<int>(),
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
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
      semesterWeeks: normalizeSemesterWeeks(semesterWeeks ?? this.semesterWeeks),
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
    required this.dailyPeriods,
    required this.periodTimes,
  });

  final String name;
  final DateTime startDate;
  final int totalWeeks;
  final int dailyPeriods;
  final List<CoursePeriodTime> periodTimes;

  Map<String, dynamic> toJson() => {
    'name': name,
    'startDate': startDate.toIso8601String(),
    'totalWeeks': totalWeeks,
    'dailyPeriods': dailyPeriods,
    'periodTimes': periodTimes.map((item) => item.toJson()).toList(),
  };

  factory TimetableConfig.fromJson(Map<String, dynamic> json) {
    return TimetableConfig(
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      totalWeeks: json['totalWeeks'] as int,
      dailyPeriods: json['dailyPeriods'] as int,
      periodTimes: (json['periodTimes'] as List<dynamic>)
          .map((item) => CoursePeriodTime.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  TimetableConfig copyWith({
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    int? dailyPeriods,
    List<CoursePeriodTime>? periodTimes,
  }) {
    return TimetableConfig(
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      dailyPeriods: dailyPeriods ?? this.dailyPeriods,
      periodTimes: periodTimes ?? this.periodTimes,
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

  factory TimetableData.fromJson(Map<String, dynamic> json) {
    return TimetableData(
      id: json['id'] as String,
      config: TimetableConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map)),
      courses: (json['courses'] as List<dynamic>)
          .map((item) => CourseItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory TimetableData.decode(String source) {
    return TimetableData.fromJson(Map<String, dynamic>.from(jsonDecode(source) as Map));
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

class AppData {
  const AppData({
    required this.activeTimetableId,
    required this.timetables,
  });

  final String activeTimetableId;
  final List<TimetableData> timetables;

  Map<String, dynamic> toJson() => {
    'activeTimetableId': activeTimetableId,
    'timetables': timetables.map((item) => item.toJson()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      activeTimetableId: json['activeTimetableId'] as String,
      timetables: (json['timetables'] as List<dynamic>)
          .map((item) => TimetableData.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory AppData.decode(String source) {
    return AppData.fromJson(Map<String, dynamic>.from(jsonDecode(source) as Map));
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
      version: json['version'] as int? ?? 1,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  String encode() => jsonEncode(toJson());

  factory ImportExportEnvelope.decode(String source) {
    return ImportExportEnvelope.fromJson(Map<String, dynamic>.from(jsonDecode(source) as Map));
  }
}

const importExportVersion = 1;
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

String encodeTimetableDataEnvelope(TimetableData data) {
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
    data: {
      'periodTimes': periodTimes.map((item) => item.toJson()).toList(),
    },
  ).encode();
}

List<CoursePeriodTime> decodePeriodTimesEnvelope(String source) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(envelope, expectedSchema: periodTimesSchema);
  return (envelope.data['periodTimes'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => CoursePeriodTime.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
}

AppData decodeAppDataEnvelope(String source) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(envelope, expectedSchema: appDataSchema);
  return AppData.fromJson(envelope.data);
}

TimetableData decodeTimetableDataEnvelope(String source) {
  final envelope = ImportExportEnvelope.decode(source);
  _ensureSupportedEnvelope(envelope, expectedSchema: timetableDataSchema);
  return TimetableData.fromJson(envelope.data);
}

void _ensureSupportedEnvelope(ImportExportEnvelope envelope, {required String expectedSchema}) {
  if (envelope.schema != expectedSchema) {
    throw const FormatException('导入文件类型不匹配');
  }
  if (envelope.version != importExportVersion) {
    throw const FormatException('导入文件版本暂不支持');
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

String formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String buildTimeRange(int startMinutes, int endMinutes) {
  return '${formatMinutes(startMinutes)} - ${formatMinutes(endMinutes)}';
}

int normalizeDayOfWeek(int? dayOfWeek) {
  final value = dayOfWeek ?? 1;
  return value.clamp(1, 7);
}

/// 周次范围留空表示“全学期有效”，这样旧数据不需要反推具体周次也能继续显示。
List<int> normalizeSemesterWeeks(List<int> semesterWeeks) {
  final normalized = semesterWeeks.where((week) => week > 0).toSet().toList()..sort();
  return normalized;
}

List<int> buildAllSemesterWeeks(int totalWeeks) {
  final safeTotalWeeks = totalWeeks < 1 ? 1 : totalWeeks;
  return List.generate(safeTotalWeeks, (index) => index + 1);
}

bool matchesSemesterWeek(CourseItem course, int selectedWeek) {
  return course.semesterWeeks.isEmpty || course.semesterWeeks.contains(selectedWeek);
}

String formatDayOfWeekLabel(int dayOfWeek) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return '星期${labels[normalizeDayOfWeek(dayOfWeek) - 1]}';
}

String formatSemesterWeeksLabel(List<int> semesterWeeks, {int? totalWeeks}) {
  final normalized = normalizeSemesterWeeks(semesterWeeks);
  if (normalized.isEmpty) {
    return totalWeeks == null ? '全学期' : '第 1-$totalWeeks 周';
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
  return '第 ${ranges.join('、')} 周';
}

/// 当课程时间恰好覆盖若干连续节次时，自动返回这些节次；否则返回空列表，表示应隐藏节次。
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
    for (var endIndex = startIndex + 1; endIndex < periodTimes.length; endIndex++) {
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
  if (json['weekdays'] is List<dynamic> && (json['weekdays'] as List<dynamic>).isNotEmpty) {
    return ((json['weekdays'] as List<dynamic>).first as num).toInt();
  }
  return 1;
}

int currentWeekFor(TimetableConfig config, {DateTime? now}) {
  final today = (now ?? DateTime.now());
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedStart = DateTime(
    config.startDate.year,
    config.startDate.month,
    config.startDate.day,
  );
  final days = normalizedToday.difference(normalizedStart).inDays;
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
  return DateTime(
    config.startDate.year,
    config.startDate.month,
    config.startDate.day,
  ).add(Duration(days: (week - 1) * 7));
}

AppData buildSampleAppData() {
  final periodTimes = buildDefaultPeriodTimes();
  final timetableA = TimetableData(
    id: 'default',
    config: TimetableConfig(
      name: '2026 春季学期',
      startDate: DateTime(2026, 2, 23),
      totalWeeks: 20,
      dailyPeriods: 12,
      periodTimes: periodTimes,
    ),
    courses: [
      CourseItem(
        id: 'c1',
        name: '高等数学',
        teacher: '陈老师',
        location: 'A-201',
        dayOfWeek: 1,
        semesterWeeks: buildAllSemesterWeeks(20),
        periods: const [1, 2],
        startMinutes: periodTimes[0].startMinutes,
        endMinutes: periodTimes[1].endMinutes,
        timeRange: buildTimeRange(periodTimes[0].startMinutes, periodTimes[1].endMinutes),
        credit: 4,
        remarks: '记得带作业',
        customFields: const {'QQ群': '123456'},
      ),
      CourseItem(
        id: 'c2',
        name: 'Flutter 开发',
        teacher: '林老师',
        location: '实验楼 402',
        dayOfWeek: 2,
        semesterWeeks: buildAllSemesterWeeks(20),
        periods: const [3, 4],
        startMinutes: periodTimes[2].startMinutes,
        endMinutes: periodTimes[3].endMinutes,
        timeRange: buildTimeRange(periodTimes[2].startMinutes, periodTimes[3].endMinutes),
        credit: 3,
        remarks: '分组项目课',
        customFields: const {'作业平台': '雨课堂'},
      ),
      CourseItem(
        id: 'c3',
        name: '大学英语',
        teacher: 'Wang',
        location: 'B-104',
        dayOfWeek: 3,
        semesterWeeks: buildAllSemesterWeeks(20),
        periods: const [5, 6],
        startMinutes: periodTimes[4].startMinutes,
        endMinutes: periodTimes[5].endMinutes,
        timeRange: buildTimeRange(periodTimes[4].startMinutes, periodTimes[5].endMinutes),
        credit: 2,
        remarks: '',
        customFields: const {},
      ),
      CourseItem(
        id: 'c4',
        name: '线性代数答疑',
        teacher: '赵老师',
        location: '线上会议',
        dayOfWeek: 2,
        semesterWeeks: buildAllSemesterWeeks(20),
        periods: const [],
        startMinutes: periodTimes[2].startMinutes + 10,
        endMinutes: periodTimes[2].endMinutes + 20,
        timeRange: buildTimeRange(periodTimes[2].startMinutes + 10, periodTimes[2].endMinutes + 20),
        credit: 0,
        remarks: '与 Flutter 课时间重叠，用于演示重叠布局',
        customFields: const {'会议号': '8866'},
      ),
    ],
  );

  final timetableB = TimetableData(
    id: 'backup',
    config: TimetableConfig(
      name: '考研复习计划',
      startDate: DateTime(2026, 3, 2),
      totalWeeks: 16,
      dailyPeriods: 8,
      periodTimes: periodTimes.take(8).toList(),
    ),
    courses: [
      CourseItem(
        id: 'b1',
        name: '政治',
        teacher: '自习',
        location: '图书馆',
        dayOfWeek: 6,
        semesterWeeks: buildAllSemesterWeeks(16),
        periods: const [1, 2, 3],
        startMinutes: periodTimes[0].startMinutes,
        endMinutes: periodTimes[2].endMinutes,
        timeRange: buildTimeRange(periodTimes[0].startMinutes, periodTimes[2].endMinutes),
        credit: 0,
        remarks: '周末专项',
        customFields: const {'目标': '1000题'},
      ),
    ],
  );

  return AppData(
    activeTimetableId: timetableA.id,
    timetables: [timetableA, timetableB],
  );
}
