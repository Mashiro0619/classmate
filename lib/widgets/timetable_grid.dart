import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

const _minuteHeight = 1.4;
const _compactHeaderHeight = 56.0;
const _regularHeaderHeight = 64.0;

class TimetableCourseTapInfo {
  const TimetableCourseTapInfo({
    required this.course,
    required this.courses,
    required this.isFullConflict,
    this.conflictKey,
  });

  final CourseItem course;
  final List<CourseItem> courses;
  final bool isFullConflict;
  final String? conflictKey;

  TimetableCourseTapInfo copyWith({
    CourseItem? course,
    List<CourseItem>? courses,
    bool? isFullConflict,
    String? conflictKey,
  }) {
    return TimetableCourseTapInfo(
      course: course ?? this.course,
      courses: courses ?? this.courses,
      isFullConflict: isFullConflict ?? this.isFullConflict,
      conflictKey: conflictKey ?? this.conflictKey,
    );
  }
}

class TimetableEmptySlotTapInfo {
  const TimetableEmptySlotTapInfo({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.periods,
  });

  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final List<int> periods;
}

/// 这里按真实时间排版课程块，这样换一套节次时间后，视觉位置也会跟着对齐。
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.timetable,
    required this.periodTimes,
    required this.weekDateStart,
    required this.selectedWeek,
    required this.localeCode,
    required this.preserveGaps,
    required this.onCourseTap,
    required this.onEmptySlotTap,
    this.displayedCourseIdForConflict,
  });

  final TimetableData timetable;
  final List<CoursePeriodTime> periodTimes;
  final DateTime weekDateStart;
  final int selectedWeek;
  final String localeCode;
  final bool preserveGaps;
  final ValueChanged<TimetableCourseTapInfo> onCourseTap;
  final ValueChanged<TimetableEmptySlotTapInfo> onEmptySlotTap;
  final String? Function(String conflictKey)? displayedCourseIdForConflict;

  @override
  Widget build(BuildContext context) {
    final slots = periodTimes.isEmpty
        ? buildPeriodTimesForCount(1)
        : periodTimes;
    final layout = _TimetableVerticalLayout(
      slots: slots,
      preserveGaps: preserveGaps,
    );
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TimetableMetrics.fromWidth(constraints.maxWidth);
        final headerHeight = metrics.compact
            ? _compactHeaderHeight
            : _regularHeaderHeight;

        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: metrics.timeLabelWidth,
                      child: _MonthHeader(
                        date: weekDateStart,
                        compact: metrics.compact,
                        localeCode: localeCode,
                      ),
                    ),
                    for (var weekday = 1; weekday <= 7; weekday++)
                      SizedBox(
                        width: metrics.dayColumnWidth,
                        child: _DayHeader(
                          weekday: weekday,
                          date: weekDateStart.add(Duration(days: weekday - 1)),
                          compact: metrics.compact,
                          localeCode: localeCode,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: layout.totalHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: metrics.timeLabelWidth,
                          child: Stack(
                            children: [
                              for (final slot in slots)
                                Positioned(
                                  top: layout.slotTop(slot),
                                  left: 0,
                                  right: 0,
                                  child: SizedBox(
                                    height: layout.slotHeight(slot),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: metrics.sidePadding,
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                slot.index.toString(),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${formatMinutes(slot.startMinutes)}\n${formatMinutes(slot.endMinutes)}',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(height: 1.05),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (var weekday = 1; weekday <= 7; weekday++)
                          Container(
                            width: metrics.dayColumnWidth,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPressStart: (details) {
                                final matchedPeriod = layout.slotForY(
                                  details.localPosition.dy,
                                );
                                onEmptySlotTap(
                                  TimetableEmptySlotTapInfo(
                                    weekday: weekday,
                                    startMinutes: matchedPeriod.startMinutes,
                                    endMinutes: matchedPeriod.endMinutes,
                                    periods: [matchedPeriod.index],
                                  ),
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final slot in slots)
                                    Positioned(
                                      top: layout.slotTop(slot),
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: layout.slotHeight(slot),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: colors.outlineVariant
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ..._buildDayLayouts(
                                    timetable: timetable,
                                    courses: timetable.courses,
                                    weekday: weekday,
                                    selectedWeek: selectedWeek,
                                    displayedCourseIdForConflict:
                                        displayedCourseIdForConflict,
                                  ).map(
                                    (item) => _CourseCard(
                                      layout: item,
                                      verticalLayout: layout,
                                      metrics: metrics,
                                      onTap: () => onCourseTap(
                                        TimetableCourseTapInfo(
                                          course: item.course,
                                          courses: item.conflictCourses,
                                          isFullConflict: item.isFullConflict,
                                          conflictKey: item.conflictKey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 这些阈值先保证整周能塞进当前宽度，再去调留白和可读性。
class _TimetableMetrics {
  const _TimetableMetrics({
    required this.timeLabelWidth,
    required this.dayColumnWidth,
    required this.courseGap,
    required this.cardPadding,
    required this.sidePadding,
    required this.compact,
  });

  final double timeLabelWidth;
  final double dayColumnWidth;
  final double courseGap;
  final double cardPadding;
  final double sidePadding;
  final bool compact;

  factory _TimetableMetrics.fromWidth(double width) {
    final safeWidth = width.isFinite && width > 0 ? width : 980.0;
    final compact = safeWidth < 920;
    final timeLabelWidth = safeWidth < 600
        ? 34.0
        : safeWidth < 840
        ? 42.0
        : 52.0;
    final availableDaysWidth = math.max(safeWidth - timeLabelWidth, 0.0);
    return _TimetableMetrics(
      timeLabelWidth: timeLabelWidth,
      dayColumnWidth: availableDaysWidth / 7,
      courseGap: safeWidth < 600
          ? 2.0
          : compact
          ? 4.0
          : 6.0,
      cardPadding: safeWidth < 600
          ? 3.0
          : compact
          ? 5.0
          : 8.0,
      sidePadding: safeWidth < 600
          ? 1.0
          : compact
          ? 2.0
          : 4.0,
      compact: compact,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.date,
    required this.compact,
    required this.localeCode,
  });

  final DateTime date;
  final bool compact;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4, vertical: 8),
      child: Center(
        child: Text(
          formatMonthLabel(date.month, localeCode: localeCode),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: compact
              ? Theme.of(context).textTheme.labelSmall
              : Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.weekday,
    required this.date,
    required this.compact,
    required this.localeCode,
  });

  final int weekday;
  final DateTime date;
  final bool compact;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = _isSameDate(date, DateTime.now());
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatWeekdayShortLabel(weekday, localeCode: localeCode),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Container(
            constraints: BoxConstraints(minWidth: compact ? 24 : 28),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 6,
              vertical: compact ? 2 : 3,
            ),
            decoration: isToday
                ? BoxDecoration(
                    color: colorScheme.primaryContainer,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.65),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              '${date.day}',
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelSmall
                          : Theme.of(context).textTheme.bodySmall)
                      ?.copyWith(
                        color: isToday ? colorScheme.onPrimaryContainer : null,
                        fontWeight: isToday ? FontWeight.w700 : null,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableVerticalLayout {
  _TimetableVerticalLayout({
    required this.slots,
    required this.preserveGaps,
  }) : _slotTops = _buildSlotTops(slots, preserveGaps) {
    totalHeight = slots.isEmpty
        ? 0
        : preserveGaps
        ? (slots.last.endMinutes - slots.first.startMinutes) * _minuteHeight
        : slots.fold<double>(
            0,
            (sum, slot) => sum + _slotHeightFor(slot),
          );
  }

  final List<CoursePeriodTime> slots;
  final bool preserveGaps;
  final List<double> _slotTops;
  late final double totalHeight;

  static List<double> _buildSlotTops(
    List<CoursePeriodTime> slots,
    bool preserveGaps,
  ) {
    if (slots.isEmpty) {
      return const [];
    }
    if (preserveGaps) {
      final startMinutes = slots.first.startMinutes;
      return [
        for (final slot in slots)
          (slot.startMinutes - startMinutes) * _minuteHeight,
      ];
    }
    var currentTop = 0.0;
    final tops = <double>[];
    for (final slot in slots) {
      tops.add(currentTop);
      currentTop += _slotHeightFor(slot);
    }
    return tops;
  }

  static double _slotHeightFor(CoursePeriodTime slot) {
    return math.max(0, slot.endMinutes - slot.startMinutes) * _minuteHeight;
  }

  int _slotIndex(CoursePeriodTime slot) {
    final index = slots.indexWhere((item) => item.index == slot.index);
    return index < 0 ? 0 : index;
  }

  double slotTop(CoursePeriodTime slot) => _slotTops[_slotIndex(slot)];

  double slotHeight(CoursePeriodTime slot) => _slotHeightFor(slot);

  double minuteToY(int minute) {
    if (slots.isEmpty) {
      return 0;
    }
    final firstStart = slots.first.startMinutes;
    final lastEnd = slots.last.endMinutes;
    final clampedMinute = minute.clamp(firstStart, lastEnd).toInt();
    if (preserveGaps) {
      return (clampedMinute - firstStart) * _minuteHeight;
    }
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      final top = _slotTops[index];
      if (clampedMinute < slot.startMinutes) {
        return top;
      }
      if (clampedMinute <= slot.endMinutes) {
        return top + (clampedMinute - slot.startMinutes) * _minuteHeight;
      }
    }
    return totalHeight;
  }

  double courseTop(CourseItem course) => minuteToY(course.startMinutes);

  double courseHeight(CourseItem course) {
    final visualHeight = minuteToY(course.endMinutes) - minuteToY(course.startMinutes);
    return math.max(92.0, visualHeight);
  }

  CoursePeriodTime slotForY(double y) {
    if (slots.isEmpty) {
      throw StateError('No period slots available');
    }
    final clampedY = totalHeight <= 0
        ? 0.0
        : y.clamp(0.0, math.max(totalHeight - 0.001, 0.0)).toDouble();
    for (var index = 0; index < slots.length; index++) {
      final bottom = _slotTops[index] + slotHeight(slots[index]);
      if (clampedY < bottom) {
        return slots[index];
      }
    }
    return slots.last;
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.layout,
    required this.verticalLayout,
    required this.metrics,
    required this.onTap,
  });

  final _CourseLayout layout;
  final _TimetableVerticalLayout verticalLayout;
  final _TimetableMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final top = verticalLayout.courseTop(layout.course);
    final height = verticalLayout.courseHeight(layout.course);
    final width = math.max(
      0.0,
      metrics.dayColumnWidth - (metrics.courseGap * 2),
    );
    final compact = width < 96 || height < 112;
    final baseColor = Color.lerp(
      colorScheme.secondaryContainer,
      colorScheme.primaryContainer,
      0.18 + (layout.priorityDepth * 0.18),
    );
    final color = (baseColor ?? colorScheme.secondaryContainer).withValues(
      alpha: layout.isFullConflict
          ? 0.94
          : layout.priorityDepth == 0
          ? 0.92
          : math.max(0.48, 0.82 - (layout.priorityDepth * 0.10)),
    );

    return Positioned(
      top: top,
      left: metrics.courseGap,
      width: width,
      height: height,
      child: Card.filled(
        color: color,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(metrics.cardPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textColor = colorScheme.onSecondaryContainer.withValues(
                  alpha: layout.priorityDepth == 0 ? 0.96 : 0.92,
                );
                final titleStyle =
                    (compact ? textTheme.titleSmall : textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: textColor,
                        );
                final bodyStyle =
                    (compact ? textTheme.bodySmall : textTheme.bodyMedium)
                        ?.copyWith(height: 1.1, color: textColor);
                final teacherStyle =
                    (compact ? textTheme.labelSmall : textTheme.labelMedium)
                        ?.copyWith(
                          height: 1.1,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        );
                final dense = height < 110;
                final medium = height < 150;
                final titleLines = dense
                    ? 3
                    : medium
                    ? (compact ? 3 : 4)
                    : (compact ? 4 : 5);
                final locationLines = dense
                    ? 2
                    : medium
                    ? 2
                    : (compact ? 2 : 3);
                final teacherLines = dense
                    ? 0
                    : medium
                    ? 1
                    : 2;

                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          layout.course.name,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        if (layout.course.location.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  teacherLines > 0 &&
                                      layout.course.teacher.isNotEmpty
                                  ? (compact ? 2 : 3)
                                  : 0,
                            ),
                            child: Text(
                              layout.course.location,
                              maxLines: locationLines,
                              overflow: TextOverflow.ellipsis,
                              style: bodyStyle,
                            ),
                          ),
                        if (teacherLines > 0 &&
                            layout.course.teacher.isNotEmpty)
                          Text(
                            layout.course.teacher,
                            maxLines: teacherLines,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: teacherStyle,
                          ),
                      ],
                    ),
                    if (layout.isFullConflict)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(compact ? 2 : 3),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            Icons.layers_outlined,
                            size: compact ? 14 : 16,
                            color: textColor,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseLayout {
  const _CourseLayout({
    required this.course,
    required this.priorityDepth,
    required this.isFullConflict,
    required this.conflictCourses,
    this.conflictKey,
  });

  final CourseItem course;
  final int priorityDepth;
  final bool isFullConflict;
  final List<CourseItem> conflictCourses;
  final String? conflictKey;
}

class _OverlapGroup {
  const _OverlapGroup(this.courses);

  final List<CourseItem> courses;
}

List<_CourseLayout> _buildDayLayouts({
  required TimetableData timetable,
  required List<CourseItem> courses,
  required int weekday,
  required int selectedWeek,
  required String? Function(String conflictKey)? displayedCourseIdForConflict,
}) {
  final dayCourses =
      courses
          .where(
            (item) =>
                item.dayOfWeek == weekday &&
                matchesSemesterWeek(item, selectedWeek),
          )
          .toList()
        ..sort((a, b) {
          final startCompare = a.startMinutes.compareTo(b.startMinutes);
          if (startCompare != 0) {
            return startCompare;
          }
          final endCompare = a.endMinutes.compareTo(b.endMinutes);
          if (endCompare != 0) {
            return endCompare;
          }
          return a.id.compareTo(b.id);
        });

  final layouts = <_CourseLayout>[];
  for (final group in _buildOverlapGroups(dayCourses)) {
    if (_isFullConflictGroup(group.courses)) {
      final conflictKey = _buildConflictKey(
        timetable.id,
        weekday,
        group.courses,
      );
      final displayedCourseId = displayedCourseIdForConflict?.call(conflictKey);
      final displayedCourse = _pickDisplayedCourse(
        group.courses,
        displayedCourseId,
      );
      final sortedCourses = [...group.courses]
        ..sort(_compareDisplayedCourseChoice);
      layouts.add(
        _CourseLayout(
          course: displayedCourse,
          priorityDepth: 0,
          isFullConflict: true,
          conflictCourses: sortedCourses,
          conflictKey: conflictKey,
        ),
      );
      continue;
    }

    final sortedCourses = [...group.courses]..sort(_comparePaintPriority);
    for (var index = 0; index < sortedCourses.length; index++) {
      layouts.add(
        _CourseLayout(
          course: sortedCourses[index],
          priorityDepth: index,
          isFullConflict: false,
          conflictCourses: [sortedCourses[index]],
        ),
      );
    }
  }
  return layouts;
}

List<_OverlapGroup> _buildOverlapGroups(List<CourseItem> courses) {
  if (courses.isEmpty) {
    return const [];
  }
  final groups = <_OverlapGroup>[];
  var currentCourses = <CourseItem>[];
  var currentEnd = -1;

  for (final course in courses) {
    if (currentCourses.isEmpty) {
      currentCourses = [course];
      currentEnd = course.endMinutes;
      continue;
    }
    if (course.startMinutes < currentEnd) {
      currentCourses.add(course);
      currentEnd = math.max(currentEnd, course.endMinutes);
      continue;
    }
    groups.add(_OverlapGroup(List<CourseItem>.from(currentCourses)));
    currentCourses = [course];
    currentEnd = course.endMinutes;
  }

  if (currentCourses.isNotEmpty) {
    groups.add(_OverlapGroup(List<CourseItem>.from(currentCourses)));
  }
  return groups;
}

bool _isFullConflictGroup(List<CourseItem> courses) {
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
    return _contains(courses[0], courses[1]) ||
        _contains(courses[1], courses[0]);
  }
  return false;
}

bool _contains(CourseItem outer, CourseItem inner) {
  return outer.startMinutes <= inner.startMinutes &&
      outer.endMinutes >= inner.endMinutes;
}

CourseItem _pickDisplayedCourse(
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

String _buildConflictKey(
  String timetableId,
  int weekday,
  List<CourseItem> courses,
) {
  final courseIds = courses.map((item) => item.id).toList()..sort();
  final startMinutes = courses
      .map((item) => item.startMinutes)
      .reduce(math.min);
  final endMinutes = courses.map((item) => item.endMinutes).reduce(math.max);
  return '$timetableId|$weekday|$startMinutes|$endMinutes|${courseIds.join(',')}';
}

/// 晚开始的课压在上层，更符合肉眼对重叠关系的直觉；开始时间一样时再优先短课。
int _comparePaintPriority(CourseItem a, CourseItem b) {
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

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
