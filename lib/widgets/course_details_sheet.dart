import 'package:flutter/material.dart';

import '../models/timetable_models.dart' show CourseItem, formatDayOfWeekLabel, formatSemesterWeeksLabel;

/// 课程详情弹窗默认只读，编辑作为二级操作，避免误触直接进入编辑。
class CourseDetailsSheet extends StatelessWidget {
  const CourseDetailsSheet({
    super.key,
    required this.course,
    required this.onEdit,
  });

  final CourseItem course;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
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
              value: course.periods.isEmpty ? course.timeRange : '${course.timeRange} · 第 ${course.periods.join('-')} 节',
            ),
            const SizedBox(height: 12),
            _DetailRow(label: '老师', value: course.teacher.isEmpty ? '未填写' : course.teacher),
            _DetailRow(label: '上课日', value: formatDayOfWeekLabel(course.dayOfWeek)),
            _DetailRow(label: '周次', value: formatSemesterWeeksLabel(course.semesterWeeks)),
            _DetailRow(label: '学分', value: course.credit == 0 ? '未填写' : course.credit.toString()),
            _DetailRow(label: '备注', value: course.remarks.isEmpty ? '无' : course.remarks),
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
    );
  }
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
          SizedBox(
            width: 52,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
