import 'package:flutter/material.dart';

import '../models/timetable_models.dart' show CourseItem, formatWeekdayLabels;

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
                    style: Theme.of(context).textTheme.headlineSmall,
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
            _DetailRow(label: '老师', value: course.teacher.isEmpty ? '未填写' : course.teacher),
            _DetailRow(label: '地点', value: course.location.isEmpty ? '未填写' : course.location),
            _DetailRow(label: '时间', value: course.timeRange),
            _DetailRow(label: '星期', value: formatWeekdayLabels(course.weekdays)),
            _DetailRow(label: '节次', value: course.periods.join(', ')),
            _DetailRow(label: '学分', value: course.credit == 0 ? '未填写' : course.credit.toString()),
            _DetailRow(label: '备注', value: course.remarks.isEmpty ? '无' : course.remarks),
            if (course.customFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('自定义字段', style: Theme.of(context).textTheme.titleMedium),
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
