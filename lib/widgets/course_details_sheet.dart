import 'package:flutter/material.dart';

import '../models/timetable_models.dart' show CourseItem, formatDayOfWeekLabel, formatSemesterWeeksLabel;

/// 课程详情弹窗默认只读，编辑作为二级操作，避免误触直接进入编辑。
class CourseDetailsSheet extends StatelessWidget {
  const CourseDetailsSheet({
    super.key,
    required this.course,
    required this.onEdit,
    this.conflictCourses = const [],
    this.onSelectDisplayedCourse,
    this.onEditConflictCourse,
  });

  final CourseItem course;
  final VoidCallback onEdit;
  final List<CourseItem> conflictCourses;
  final ValueChanged<CourseItem>? onSelectDisplayedCourse;
  final ValueChanged<CourseItem>? onEditConflictCourse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherConflictCourses = conflictCourses.where((item) => item.id != course.id).toList();

    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: '编辑课程',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PrimaryInfoCard(
                icon: Icons.place_outlined,
                label: '地点',
                value: course.location.isEmpty ? '未填写' : course.location,
              ),
              const SizedBox(height: 10),
              _PrimaryInfoCard(
                icon: Icons.schedule,
                label: '时间',
                value: course.periods.isEmpty ? course.timeRange : '${course.timeRange} · ${_formatPeriodsLabel(course.periods)}',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: '老师', value: course.teacher.isEmpty ? '未填写' : course.teacher),
              _DetailRow(label: '上课日', value: formatDayOfWeekLabel(course.dayOfWeek)),
              _DetailRow(label: '周次', value: formatSemesterWeeksLabel(course.semesterWeeks)),
              _DetailRow(label: '学分', value: course.credit == 0 ? '未填写' : course.credit.toString()),
              _DetailRow(label: '备注', value: course.remarks.isEmpty ? '无' : course.remarks),
              if (otherConflictCourses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('冲突课程', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in otherConflictCourses)
                  Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.location.isEmpty ? '未填写地点' : item.location} · ${item.timeRange}${item.periods.isEmpty ? '' : ' · ${_formatPeriodsLabel(item.periods)}'}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (onSelectDisplayedCourse != null)
                            IconButton(
                              tooltip: '设为外部显示',
                              onPressed: () => onSelectDisplayedCourse!(item),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          if (onEditConflictCourse != null)
                            IconButton(
                              tooltip: '编辑这门课',
                              onPressed: () => onEditConflictCourse!(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (course.customFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('自定义字段', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final entry in course.customFields.entries)
                  _DetailRow(label: entry.key, value: entry.value.toString()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPeriodsLabel(List<int> periods) {
  if (periods.isEmpty) {
    return '';
  }
  final sorted = [...periods]..sort();
  return '第 ${sorted.first}-${sorted.last} 节';
}

class _PrimaryInfoCard extends StatelessWidget {
  const _PrimaryInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 7,
            child: Text(value, softWrap: true),
          ),
        ],
      ),
    );
  }
}
