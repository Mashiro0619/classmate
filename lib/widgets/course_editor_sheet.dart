import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

/// 编辑器返回值：要么保存课程，要么删除课程，要么取消关闭。
class CourseEditorResult {
  const CourseEditorResult.save(this.course) : delete = false;
  const CourseEditorResult.delete()
      : course = null,
        delete = true;

  final CourseItem? course;
  final bool delete;
}

/// 课程编辑底部弹窗：
/// - 上课日使用单选
/// - 周次通过二级弹窗选择
/// - 时间段始终优先于节次，节次只作为自动推导出的附属信息展示
class CourseEditorSheet extends StatefulWidget {
  const CourseEditorSheet({
    super.key,
    required this.periodTimes,
    required this.totalWeeks,
    required this.dayOfWeek,
    this.initialCourse,
  });

  final List<CoursePeriodTime> periodTimes;
  final int totalWeeks;
  final int dayOfWeek;
  final CourseItem? initialCourse;

  @override
  State<CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<CourseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _locationController;
  late final TextEditingController _creditController;
  late final TextEditingController _remarksController;
  late final TextEditingController _customFieldsController;

  late int _selectedDayOfWeek;
  late List<int> _selectedSemesterWeeks;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCourse;
    final defaultStartMinutes = widget.periodTimes.isNotEmpty ? widget.periodTimes.first.startMinutes : 8 * 60;
    final defaultEndMinutes = widget.periodTimes.length > 1
        ? widget.periodTimes[1].endMinutes
        : widget.periodTimes.isNotEmpty
        ? widget.periodTimes.first.endMinutes
        : (8 * 60) + 45;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _teacherController = TextEditingController(text: initial?.teacher ?? '');
    _locationController = TextEditingController(text: initial?.location ?? '');
    _creditController = TextEditingController(
      text: initial == null || initial.credit == 0 ? '' : initial.credit.toString(),
    );
    _remarksController = TextEditingController(text: initial?.remarks ?? '');
    _customFieldsController = TextEditingController(
      text: initial == null
          ? ''
          : initial.customFields.entries.map((entry) => '${entry.key}:${entry.value}').join('\n'),
    );
    _selectedDayOfWeek = initial?.dayOfWeek ?? widget.dayOfWeek;
    _selectedSemesterWeeks = normalizeSemesterWeeks(initial?.semesterWeeks ?? buildAllSemesterWeeks(widget.totalWeeks));
    _startTime = _timeOfDayFromMinutes(initial?.startMinutes ?? defaultStartMinutes);
    _endTime = _timeOfDayFromMinutes(initial?.endMinutes ?? defaultEndMinutes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _creditController.dispose();
    _remarksController.dispose();
    _customFieldsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedPeriods = _matchedPeriods;

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.58,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.initialCourse == null ? '添加课程' : '编辑课程',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: '课程名称')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: '上课地点'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('上课日'),
                        subtitle: Text(formatDayOfWeekLabel(_selectedDayOfWeek)),
                        trailing: const Icon(Icons.today_outlined),
                        onTap: _pickDayOfWeek,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('周次'),
                        subtitle: Text(formatSemesterWeeksLabel(_selectedSemesterWeeks, totalWeeks: widget.totalWeeks)),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: _pickSemesterWeeks,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('开始时间'),
                              subtitle: Text(_formatTimeOfDay(_startTime)),
                              trailing: const Icon(Icons.schedule),
                              onTap: () => _pickTime(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('结束时间'),
                              subtitle: Text(_formatTimeOfDay(_endTime)),
                              trailing: const Icon(Icons.schedule),
                              onTap: () => _pickTime(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      if (matchedPeriods.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('关联节次'),
                          subtitle: Text('第 ${matchedPeriods.first}-${matchedPeriods.last} 节'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _teacherController,
                              decoration: const InputDecoration(labelText: '老师姓名'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _creditController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: '学分'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarksController,
                        decoration: const InputDecoration(labelText: '备注'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customFieldsController,
                        decoration: const InputDecoration(
                          labelText: '自定义字段',
                          hintText: '每行一个，格式：键:值',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.initialCourse != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(const CourseEditorResult.delete()),
                      child: const Text('删除'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int> get _matchedPeriods => matchPeriodsForTimeRange(
        widget.periodTimes,
        _minutesFromTimeOfDay(_startTime),
        _minutesFromTimeOfDay(_endTime),
      );

  Future<void> _pickDayOfWeek() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择上课日'),
          content: SizedBox(
            width: 320,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: 7,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: day == _selectedDayOfWeek ? Theme.of(context).colorScheme.secondaryContainer : null,
                  title: Text(formatDayOfWeekLabel(day)),
                  trailing: day == _selectedDayOfWeek ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(day),
                );
              },
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _selectedDayOfWeek = result);
    }
  }

  Future<void> _pickSemesterWeeks() async {
    final draft = {..._selectedSemesterWeeks};
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择周次'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              draft
                                ..clear()
                                ..addAll(buildAllSemesterWeeks(widget.totalWeeks));
                            }),
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: () => setState(() => draft.clear()),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: widget.totalWeeks,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.6,
                        ),
                        itemBuilder: (context, index) {
                          final week = index + 1;
                          final selected = draft.contains(week);
                          final colorScheme = Theme.of(context).colorScheme;
                          return Material(
                            color: selected
                                ? colorScheme.secondaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    draft.remove(week);
                                  } else {
                                    draft.add(week);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      selected ? Icons.check : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '$week',
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(normalizeSemesterWeeks(draft.toList())),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null) {
      return;
    }
    setState(() {
      _selectedSemesterWeeks = result.isEmpty ? buildAllSemesterWeeks(widget.totalWeeks) : result;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    final startMinutes = _minutesFromTimeOfDay(_startTime);
    final endMinutes = _minutesFromTimeOfDay(_endTime);
    if (_nameController.text.trim().isEmpty || startMinutes >= endMinutes) {
      return;
    }

    final course = CourseItem(
      id: widget.initialCourse?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      location: _locationController.text.trim(),
      dayOfWeek: _selectedDayOfWeek,
      semesterWeeks: normalizeSemesterWeeks(_selectedSemesterWeeks),
      periods: _matchedPeriods,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      timeRange: buildTimeRange(startMinutes, endMinutes),
      credit: double.tryParse(_creditController.text.trim()) ?? 0,
      remarks: _remarksController.text.trim(),
      customFields: _parseCustomFields(_customFieldsController.text),
    );
    Navigator.of(context).pop(CourseEditorResult.save(course));
  }

  TimeOfDay _timeOfDayFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _minutesFromTimeOfDay(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> _parseCustomFields(String value) {
    final result = <String, dynamic>{};
    for (final line in value.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final separator = trimmed.indexOf(':');
      if (separator <= 0) {
        result[trimmed] = '';
        continue;
      }
      final key = trimmed.substring(0, separator).trim();
      final content = trimmed.substring(separator + 1).trim();
      result[key] = content;
    }
    return result;
  }
}
