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

/// 课程编辑弹窗支持任意时间范围，不再强依赖标准节次边界。
class CourseEditorSheet extends StatefulWidget {
  const CourseEditorSheet({
    super.key,
    required this.periodTimes,
    required this.weekday,
    this.initialCourse,
  });

  final List<CoursePeriodTime> periodTimes;
  final int weekday;
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

  late int _weekday;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Set<int> _selectedPeriods;

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
    _weekday = initial?.weekday ?? widget.weekday;
    _startTime = _timeOfDayFromMinutes(initial?.startMinutes ?? defaultStartMinutes);
    _endTime = _timeOfDayFromMinutes(initial?.endMinutes ?? defaultEndMinutes);
    _selectedPeriods = {...?initial?.periods};
    if (_selectedPeriods.isEmpty) {
      final fallbackPeriods = widget.periodTimes.take(2).map((slot) => slot.index).toSet();
      _selectedPeriods = fallbackPeriods.isEmpty ? {1} : fallbackPeriods;
    }
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: '上课地点'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _weekday,
                      decoration: const InputDecoration(labelText: '星期'),
                      items: const [1, 2, 3, 4, 5, 6, 7]
                          .map((day) => DropdownMenuItem(value: day, child: Text('星期$day')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _weekday = value);
                        }
                      },
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
              const SizedBox(height: 12),
              Text('关联节次', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.periodTimes
                    .map(
                      (slot) => FilterChip(
                        label: Text(slot.index.toString()),
                        selected: _selectedPeriods.contains(slot.index),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPeriods.add(slot.index);
                            } else {
                              _selectedPeriods.remove(slot.index);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
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
              const SizedBox(height: 20),
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
      weekday: _weekday,
      periods: (_selectedPeriods.toList()..sort()).toList(),
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
