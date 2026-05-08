import 'package:flutter/material.dart';

import '../models/course_item.dart';
import 'constants.dart';

Color deriveLiveCourseOutlineColorFromSeed(Color seedColor) {
  final hsl = HSLColor.fromColor(seedColor);
  final lightness = (hsl.lightness - 0.11).clamp(0.20, 0.74).toDouble();
  final saturation = (hsl.saturation + 0.08).clamp(0.12, 1.0).toDouble();
  return hsl.withLightness(lightness).withSaturation(saturation).toColor();
}

double normalizeLiveCourseOutlineWidth(double? width) {
  return (width ?? defaultLiveCourseOutlineWidth).clamp(
    minLiveCourseOutlineWidth,
    maxLiveCourseOutlineWidth,
  ).toDouble();
}

String normalizeLiveCourseOutlineMode(String? mode) {
  switch (mode) {
    case liveCourseOutlineModeAllDisplayed:
      return liveCourseOutlineModeAllDisplayed;
    case liveCourseOutlineModeCurrentOrNext:
    default:
      return liveCourseOutlineModeCurrentOrNext;
  }
}

String normalizeColorfulCourseTextColorMode(String? mode) {
  switch (mode) {
    case colorfulCourseTextColorModeCustom:
      return colorfulCourseTextColorModeCustom;
    case colorfulCourseTextColorModeAuto:
    default:
      return colorfulCourseTextColorModeAuto;
  }
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

String normalizeThemeColorMode(String? themeColorMode) {
  switch (themeColorMode) {
    case themeColorModeColorful:
      return themeColorModeColorful;
    case themeColorModeSingle:
    default:
      return themeColorModeSingle;
  }
}

String normalizeSchoolImportParserSource(String? source) {
  switch (source) {
    case schoolImportParserSourceCustomOpenAi:
      return schoolImportParserSourceCustomOpenAi;
    case schoolImportParserSourceOfficial:
    default:
      return schoolImportParserSourceOfficial;
  }
}

String normalizeCourseColorName(String? courseName) {
  return courseName?.trim() ?? '';
}

Map<String, int> decodeColorValueMap(dynamic value) {
  if (value is! Map) {
    return const {};
  }
  final result = <String, int>{};
  value.forEach((key, item) {
    final normalizedKey = '$key'.trim();
    final colorValue = (item as num?)?.toInt();
    if (normalizedKey.isEmpty || colorValue == null) {
      return;
    }
    result[normalizedKey] = colorValue;
  });
  return result;
}

List<int> normalizeSemesterWeeks(List<int> semesterWeeks) {
  final normalized = semesterWeeks.where((week) => week > 0).toSet().toList()
    ..sort();
  return normalized;
}

List<int> buildAllSemesterWeeks(int totalWeeks) {
  final safeTotalWeeks = normalizeTimetableWeeks(totalWeeks);
  return List.generate(safeTotalWeeks, (index) => index + 1);
}

// Period time construction

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

// Forward declaration — CoursePeriodTime will be defined in course_item.dart;
// the models barrel resolves this via re-export order.
// These functions are used by course_item.dart and timetable_data.dart.
// Since Flutter resolves imports at the library level, the barrel file
// ensures all symbols are available.
