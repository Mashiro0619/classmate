import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

const _minuteHeight = 1.4;
const _headerHeight = 56.0;

/// 课表主网格：
/// - 负责按真实时间定位课程块
/// - 负责按优先级直接重叠显示冲突课程
/// - 负责在不同宽度下动态调整列宽
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
                                      ..._buildDayLayouts(timetable.courses, weekday).map(
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

/// 针对不同窗口宽度生成网格布局参数，保证窄窗口下仍可读。
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
    final availableDaysWidth = math.max(safeWidth - timeLabelWidth, 7 * 92.0);
    final computedDayWidth = availableDaysWidth / 7;
    return _TimetableMetrics(
      timeLabelWidth: timeLabelWidth,
      dayColumnWidth: computedDayWidth.clamp(92.0, 180.0),
      courseGap: compact ? 4.0 : 6.0,
      cardPadding: compact ? 6.0 : 10.0,
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
          Text('${date.month}/${date.day}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// 单个课程块：
/// - 统一占满单日列宽，不再并排分栏
/// - 根据冲突优先级调整颜色深浅
/// - 在高卡片里把标题/地点/时间分布得更均匀
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
    final width = metrics.dayColumnWidth - (metrics.courseGap * 2);
    final compact = width < 110 || height < 120;
    final color = Color.lerp(
      colorScheme.secondaryContainer,
      colorScheme.primaryContainer,
      0.18 + (layout.priorityDepth * 0.18),
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
                final titleStyle = (compact ? textTheme.titleSmall : textTheme.titleMedium)?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                );
                final bodyStyle = (compact ? textTheme.bodySmall : textTheme.bodyMedium)?.copyWith(height: 1.15);
                final timeStyle = textTheme.labelMedium?.copyWith(height: 1.15);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layout.course.name,
                      maxLines: compact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    Expanded(
                      child: Align(
                        alignment: compact ? Alignment.topLeft : Alignment.centerLeft,
                        child: Text(
                          layout.course.location,
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      layout.course.timeRange,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: timeStyle,
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

/// 课程布局实体不再负责横向分栏，而是记录重叠优先级深度。
class _CourseLayout {
  const _CourseLayout({
    required this.course,
    required this.priorityDepth,
  });

  final CourseItem course;
  final int priorityDepth;
}

/// 构建单日课程列表时，直接返回绘制顺序：
/// - 低优先级课程先画在底层
/// - 高优先级课程后画在顶层
/// 这样重叠区域就会优先响应顶部课程。
List<_CourseLayout> _buildDayLayouts(List<CourseItem> courses, int weekday) {
  final dayCourses = courses.where((item) => item.weekday == weekday).toList()
    ..sort((a, b) => _comparePaintPriority(a, b));

  return List.generate(
    dayCourses.length,
    (index) => _CourseLayout(course: dayCourses[index], priorityDepth: index),
  );
}

/// 优先级规则：更短、更局部的课程压在更大的课程上层；
/// 若时长相同，则更晚开始的课程优先级更高。
int _comparePaintPriority(CourseItem a, CourseItem b) {
  final durationCompare = (b.endMinutes - b.startMinutes).compareTo(a.endMinutes - a.startMinutes);
  if (durationCompare != 0) {
    return durationCompare;
  }
  final startCompare = a.startMinutes.compareTo(b.startMinutes);
  if (startCompare != 0) {
    return startCompare;
  }
  return a.id.compareTo(b.id);
}
