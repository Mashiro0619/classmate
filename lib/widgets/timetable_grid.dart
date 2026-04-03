import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

const _minuteHeight = 1.4;
const _headerHeight = 56.0;

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

/// 课表主网格：
/// - 负责按真实时间定位课程块
/// - 完全冲突显示主课程并标记冲突
/// - 部分冲突继续重叠显示，晚开始课程位于上层
/// - 负责在不同宽度下动态调整列宽
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.timetable,
    required this.periodTimes,
    required this.weekDateStart,
    required this.selectedWeek,
    required this.onCourseTap,
    required this.onEmptySlotTap,
    this.displayedCourseIdForConflict,
  });

  final TimetableData timetable;
  final List<CoursePeriodTime> periodTimes;
  final DateTime weekDateStart;
  final int selectedWeek;
  final ValueChanged<TimetableCourseTapInfo> onCourseTap;
  final ValueChanged<int> onEmptySlotTap;
  final String? Function(String conflictKey)? displayedCourseIdForConflict;

  @override
  Widget build(BuildContext context) {
    final slots = periodTimes.isEmpty ? buildPeriodTimesForCount(1) : periodTimes;
    final startMinutes = slots.first.startMinutes;
    final endMinutes = slots.last.endMinutes;
    final totalHeight = (endMinutes - startMinutes) * _minuteHeight;
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TimetableMetrics.fromWidth(constraints.maxWidth);

        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              SizedBox(
                height: _headerHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: metrics.timeLabelWidth,
                      child: _MonthHeader(
                        date: weekDateStart,
                        compact: metrics.compact,
                      ),
                    ),
                    for (var weekday = 1; weekday <= 7; weekday++)
                      SizedBox(
                        width: metrics.dayColumnWidth,
                        child: _DayHeader(
                          weekday: weekday,
                          date: weekDateStart.add(Duration(days: weekday - 1)),
                          compact: metrics.compact,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: totalHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: metrics.timeLabelWidth,
                          child: Stack(
                            children: [
                              for (final slot in slots)
                                Positioned(
                                  top: (slot.startMinutes - startMinutes) * _minuteHeight,
                                  left: 0,
                                  right: 0,
                                  child: SizedBox(
                                    height: (slot.endMinutes - slot.startMinutes) * _minuteHeight,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: metrics.sidePadding),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                slot.index.toString(),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${formatMinutes(slot.startMinutes)}\n${formatMinutes(slot.endMinutes)}',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1.05),
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
                                left: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.25)),
                              ),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: () => onEmptySlotTap(weekday),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final slot in slots)
                                    Positioned(
                                      top: (slot.startMinutes - startMinutes) * _minuteHeight,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: (slot.endMinutes - slot.startMinutes) * _minuteHeight,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.18)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ..._buildDayLayouts(
                                    timetable: timetable,
                                    courses: timetable.courses,
                                    weekday: weekday,
                                    selectedWeek: selectedWeek,
                                    displayedCourseIdForConflict: displayedCourseIdForConflict,
                                  ).map(
                                    (item) => _CourseCard(
                                      layout: item,
                                      dayStartMinutes: startMinutes,
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

/// 针对不同窗口宽度生成网格布局参数，核心目标是整周必须始终压缩进当前视口。
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
    final timeLabelWidth = safeWidth < 600 ? 34.0 : safeWidth < 840 ? 42.0 : 52.0;
    final availableDaysWidth = math.max(safeWidth - timeLabelWidth, 0.0);
    return _TimetableMetrics(
      timeLabelWidth: timeLabelWidth,
      dayColumnWidth: math.min(availableDaysWidth / 7, 180.0),
      courseGap: safeWidth < 600 ? 2.0 : compact ? 4.0 : 6.0,
      cardPadding: safeWidth < 600 ? 3.0 : compact ? 5.0 : 8.0,
      sidePadding: safeWidth < 600 ? 1.0 : compact ? 2.0 : 4.0,
      compact: compact,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.date,
    required this.compact,
  });

  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4, vertical: 8),
      child: Center(
        child: Text(
          '${date.month}月',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium,
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
  });

  final int weekday;
  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            labels[weekday - 1],
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: compact ? Theme.of(context).textTheme.labelMedium : Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.layout,
    required this.dayStartMinutes,
    required this.metrics,
    required this.onTap,
  });

  final _CourseLayout layout;
  final int dayStartMinutes;
  final _TimetableMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final top = (layout.course.startMinutes - dayStartMinutes) * _minuteHeight;
    final height = math.max(
      92.0,
      (layout.course.endMinutes - layout.course.startMinutes) * _minuteHeight - metrics.courseGap,
    ).toDouble();
    final width = math.max(0.0, metrics.dayColumnWidth - (metrics.courseGap * 2));
    final compact = width < 110 || height < 120;
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
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(metrics.cardPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textColor = colorScheme.onSecondaryContainer.withValues(
                  alpha: layout.priorityDepth == 0 ? 0.96 : 0.92,
                );
                final titleStyle = (compact ? textTheme.titleSmall : textTheme.titleMedium)?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: textColor,
                );
                final bodyStyle = (compact ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
                  height: 1.1,
                  color: textColor,
                );
                final teacherStyle = (compact ? textTheme.labelSmall : textTheme.labelMedium)?.copyWith(
                  height: 1.1,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                );
                final titleLines = height < 118 ? 2 : compact ? 3 : 4;
                final locationLines = height < 118 ? 1 : compact ? 2 : 3;
                final teacherLines = height < 118 ? 1 : 2;

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
                        SizedBox(height: compact ? 3 : 6),
                        if (layout.course.location.isNotEmpty)
                          Text(
                            layout.course.location,
                            maxLines: locationLines,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle,
                          ),
                        if (layout.course.location.isNotEmpty) SizedBox(height: compact ? 2 : 4),
                        if (layout.course.teacher.isNotEmpty)
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
                          padding: EdgeInsets.all(compact ? 3 : 4),
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
  final dayCourses = courses
      .where((item) => item.dayOfWeek == weekday && matchesSemesterWeek(item, selectedWeek))
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
      final conflictKey = _buildConflictKey(timetable.id, weekday, group.courses);
      final displayedCourseId = displayedCourseIdForConflict?.call(conflictKey);
      final displayedCourse = _pickDisplayedCourse(group.courses, displayedCourseId);
      final sortedCourses = [...group.courses]..sort(_compareDisplayedCourseChoice);
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
    (item) => item.startMinutes == first.startMinutes && item.endMinutes == first.endMinutes,
  );
  if (allSameRange) {
    return true;
  }
  if (courses.length == 2) {
    return _contains(courses[0], courses[1]) || _contains(courses[1], courses[0]);
  }
  return false;
}

bool _contains(CourseItem outer, CourseItem inner) {
  return outer.startMinutes <= inner.startMinutes && outer.endMinutes >= inner.endMinutes;
}

CourseItem _pickDisplayedCourse(List<CourseItem> courses, String? displayedCourseId) {
  for (final course in courses) {
    if (course.id == displayedCourseId) {
      return course;
    }
  }
  final sorted = [...courses]..sort(_compareDisplayedCourseChoice);
  return sorted.first;
}

int _compareDisplayedCourseChoice(CourseItem a, CourseItem b) {
  final durationCompare = (b.endMinutes - b.startMinutes).compareTo(a.endMinutes - a.startMinutes);
  if (durationCompare != 0) {
    return durationCompare;
  }
  final startCompare = b.startMinutes.compareTo(a.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  return a.id.compareTo(b.id);
}

String _buildConflictKey(String timetableId, int weekday, List<CourseItem> courses) {
  final courseIds = courses.map((item) => item.id).toList()..sort();
  final startMinutes = courses.map((item) => item.startMinutes).reduce(math.min);
  final endMinutes = courses.map((item) => item.endMinutes).reduce(math.max);
  return '$timetableId|$weekday|$startMinutes|$endMinutes|${courseIds.join(',')}';
}

/// 部分冲突规则：开始时间更晚的课程位于上层；若开始时间相同，则更短课程优先级更高。
int _comparePaintPriority(CourseItem a, CourseItem b) {
  final startCompare = a.startMinutes.compareTo(b.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  final durationCompare = (b.endMinutes - b.startMinutes).compareTo(a.endMinutes - a.startMinutes);
  if (durationCompare != 0) {
    return durationCompare;
  }
  return a.id.compareTo(b.id);
}
