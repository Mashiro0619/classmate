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
    required this.weekdays,
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
  final List<int> weekdays;
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
    'weekdays': normalizeWeekdays(weekdays),
    'periods': periods,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'timeRange': timeRange,
    'credit': credit,
    'remarks': remarks,
    'customFields': customFields,
  };

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    final weekdayValues = json['weekdays'] is List<dynamic>
        ? (json['weekdays'] as List<dynamic>).cast<int>()
        : <int>[json['weekday'] as int];
    return CourseItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      location: json['location'] as String? ?? '',
      weekdays: normalizeWeekdays(weekdayValues),
      periods: (json['periods'] as List<dynamic>).cast<int>(),
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
    List<int>? weekdays,
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
      weekdays: normalizeWeekdays(weekdays ?? this.weekdays),
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

/// 统一整理星期列表，避免出现重复、越界或空列表。
List<int> normalizeWeekdays(List<int> weekdays) {
  final normalized = weekdays.where((day) => day >= 1 && day <= 7).toSet().toList()..sort();
  return normalized.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : normalized;
}

String formatWeekdayLabels(List<int> weekdays) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return normalizeWeekdays(weekdays).map((day) => '星期${labels[day - 1]}').join('、');
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
        weekdays: const [1],
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
        weekdays: const [2],
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
        weekdays: const [3],
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
        weekdays: const [2],
        periods: const [3],
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
        weekdays: const [6],
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
