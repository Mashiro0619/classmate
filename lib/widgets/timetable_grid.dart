import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

const _minuteHeight = 1.4;
const _headerHeight = 56.0;

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.timetable,
    required this.weekDateStart,
    required this.onCourseTap,
    required this.onEmptySlotTap,
  });

  final TimetableData timetable;
  final DateTime weekDateStart;
  final ValueChanged<CourseItem> onCourseTap;
  final ValueChanged<int> onEmptySlotTap;

  @override
  Widget build(BuildContext context) {
    final slots = timetable.config.periodTimes;
    final startMinutes = slots.first.startMinutes;
    final endMinutes = slots.last.endMinutes;
    final totalHeight = (endMinutes - startMinutes) * _minuteHeight;
    final colors = Theme.of(context).colorScheme;
    final grouped = _buildLayout(timetable.courses);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TimetableMetrics.fromWidth(constraints.maxWidth);
        final requiredWidth = metrics.timeLabelWidth + (metrics.dayColumnWidth * 7);

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: math.max(requiredWidth, constraints.maxWidth),
              child: Column(
                children: [
                  SizedBox(
                    height: _headerHeight,
                    child: Row(
                      children: [
                        SizedBox(width: metrics.timeLabelWidth),
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
                                          padding: EdgeInsets.only(right: metrics.sidePadding),
                                          child: FittedBox(
                                            alignment: Alignment.topRight,
                                            fit: BoxFit.scaleDown,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  slot.index.toString(),
                                                  style: Theme.of(context).textTheme.labelLarge,
                                                ),
                                                Text(
                                                  '${formatMinutes(slot.startMinutes)}\n${formatMinutes(slot.endMinutes)}',
                                                  textAlign: TextAlign.right,
                                                  style: Theme.of(context).textTheme.labelSmall,
                                                ),
                                              ],
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
                                    left: BorderSide(color: colors.outlineVariant),
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
                                                top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ...grouped.where((item) => item.course.weekday == weekday).map(
                                        (item) => _CourseCard(
                                          layout: item,
                                          dayStartMinutes: startMinutes,
                                          metrics: metrics,
                                          onTap: () => onCourseTap(item.course),
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
            ),
          ),
        );
      },
    );
  }
}

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
    final compact = safeWidth < 840;
    final timeLabelWidth = compact ? 56.0 : 68.0;
    final availableDaysWidth = math.max(safeWidth - timeLabelWidth, 7 * 88.0);
    final computedDayWidth = availableDaysWidth / 7;
    return _TimetableMetrics(
      timeLabelWidth: timeLabelWidth,
      dayColumnWidth: computedDayWidth.clamp(88.0, 180.0),
      courseGap: compact ? 4.0 : 6.0,
      cardPadding: compact ? 6.0 : 8.0,
      sidePadding: compact ? 4.0 : 8.0,
      compact: compact,
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
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '星期${labels[weekday - 1]}',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            '${date.month}/${date.day}',
            style: Theme.of(context).textTheme.bodySmall,
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
      84.0,
      (layout.course.endMinutes - layout.course.startMinutes) * _minuteHeight - metrics.courseGap,
    ).toDouble();
    final availableWidth = metrics.dayColumnWidth - metrics.courseGap * (layout.columns + 1);
    final slotWidth = math.max(56.0, availableWidth / layout.columns);
    final left = metrics.courseGap + layout.column * (slotWidth + metrics.courseGap);
    final narrow = slotWidth < 92;

    return Positioned(
      top: top,
      left: left,
      width: slotWidth,
      height: height,
      child: Card.filled(
        color: colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(metrics.cardPadding),
            child: DefaultTextStyle(
              style: textTheme.bodySmall ?? const TextStyle(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final nameStyle = (narrow ? textTheme.titleSmall : textTheme.titleMedium)?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: narrow ? 13 : null,
                    height: 1.1,
                  );
                  final locationStyle = (narrow ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(
                    fontSize: narrow ? 11 : null,
                    height: 1.1,
                  );
                  final timeStyle = textTheme.labelMedium?.copyWith(
                    fontSize: narrow ? 10 : null,
                    height: 1.1,
                  );

                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layout.course.name,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: nameStyle,
                          ),
                          SizedBox(height: narrow ? 2 : 4),
                          Text(
                            layout.course.location,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: locationStyle,
                          ),
                          SizedBox(height: narrow ? 2 : 6),
                          Text(
                            layout.course.timeRange,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: timeStyle,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
    required this.column,
    required this.columns,
  });

  final CourseItem course;
  final int column;
  final int columns;
}

List<_CourseLayout> _buildLayout(List<CourseItem> courses) {
  final layouts = <_CourseLayout>[];
  for (var weekday = 1; weekday <= 7; weekday++) {
    final dayCourses = courses.where((item) => item.weekday == weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final active = <_CourseLayout>[];
    final cluster = <_CourseLayout>[];

    void flushCluster() {
      if (cluster.isEmpty) {
        return;
      }
      var maxColumns = 1;
      for (final item in cluster) {
        if (item.column + 1 > maxColumns) {
          maxColumns = item.column + 1;
        }
      }
      layouts.addAll(
        cluster.map(
          (item) => _CourseLayout(
            course: item.course,
            column: item.column,
            columns: maxColumns,
          ),
        ),
      );
      cluster.clear();
    }

    for (final course in dayCourses) {
      active.removeWhere((item) => item.course.endMinutes <= course.startMinutes);
      if (active.isEmpty) {
        flushCluster();
      }
      var column = 0;
      while (active.any((item) => item.column == column)) {
        column++;
      }
      final layout = _CourseLayout(course: course, column: column, columns: 1);
      active.add(layout);
      cluster.add(layout);
    }
    flushCluster();
  }
  return layouts;
}
