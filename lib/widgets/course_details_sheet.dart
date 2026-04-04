import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart'
    show CourseItem, formatDayOfWeekLabel, formatSemesterWeeksLabel;

/// 详情先保持只读，编辑放成二级动作，能少很多误触和来回撤销。
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
    final l10n = AppLocalizations.of(context)!;
    final otherConflictCourses = conflictCourses
        .where((item) => item.id != course.id)
        .toList();

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
                    tooltip: l10n.editCourseTooltip,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PrimaryInfoCard(
                icon: Icons.place_outlined,
                label: l10n.place,
                value: course.location.isEmpty
                    ? l10n.notFilled
                    : course.location,
              ),
              const SizedBox(height: 10),
              _PrimaryInfoCard(
                icon: Icons.schedule,
                label: l10n.time,
                value: course.periods.isEmpty
                    ? course.timeRange
                    : '${course.timeRange} · ${_formatPeriodsLabel(l10n, course.periods)}',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: l10n.teacherName,
                value: course.teacher.isEmpty ? l10n.notFilled : course.teacher,
              ),
              _DetailRow(
                label: l10n.dayOfWeek,
                value: formatDayOfWeekLabel(
                  course.dayOfWeek,
                  localeCode: Localizations.localeOf(context).languageCode,
                ),
              ),
              _DetailRow(
                label: l10n.semesterWeeks,
                value: formatSemesterWeeksLabel(
                  course.semesterWeeks,
                  localeCode: Localizations.localeOf(context).languageCode,
                ),
              ),
              _DetailRow(
                label: l10n.credits,
                value: course.credit == 0
                    ? l10n.notFilled
                    : course.credit.toString(),
              ),
              _DetailRow(
                label: l10n.remarks,
                value: course.remarks.isEmpty ? l10n.none : course.remarks,
              ),
              if (otherConflictCourses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.conflictCourses, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final item in otherConflictCourses)
                  Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.location.isEmpty ? l10n.locationNotFilled : item.location} · ${item.timeRange}${item.periods.isEmpty ? '' : ' · ${_formatPeriodsLabel(l10n, item.periods)}'}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (onSelectDisplayedCourse != null)
                            IconButton(
                              tooltip: l10n.setAsDisplayed,
                              onPressed: () => onSelectDisplayedCourse!(item),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          if (onEditConflictCourse != null)
                            IconButton(
                              tooltip: l10n.editThisCourse,
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
                Text(l10n.customFields, style: theme.textTheme.titleMedium),
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

String _formatPeriodsLabel(AppLocalizations l10n, List<int> periods) {
  if (periods.isEmpty) {
    return '';
  }
  final sorted = [...periods]..sort();
  return l10n.periodRangeLabel(sorted.first, sorted.last);
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
  const _DetailRow({required this.label, required this.value});

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
          Flexible(flex: 7, child: Text(value, softWrap: true)),
        ],
      ),
    );
  }
}
