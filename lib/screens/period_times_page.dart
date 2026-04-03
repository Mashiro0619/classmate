import 'package:flutter/material.dart';

import '../models/timetable_models.dart';

/// 节次时间编辑独立成页面，避免把大量时间设置塞进主设置弹窗。
class PeriodTimesPage extends StatefulWidget {
  const PeriodTimesPage({
    super.key,
    required this.periodTimes,
  });

  final List<CoursePeriodTime> periodTimes;

  @override
  State<PeriodTimesPage> createState() => _PeriodTimesPageState();
}

class _PeriodTimesPageState extends State<PeriodTimesPage> {
  late List<CoursePeriodTime> _periodTimes;

  @override
  void initState() {
    super.initState();
    _periodTimes = widget.periodTimes.map((item) => item.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('节次时间'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_periodTimes),
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _periodTimes.length,
        itemBuilder: (context, index) {
          final period = _periodTimes[index];
          return Card.outlined(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 64, child: Text('第 ${period.index} 节')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开始'),
                      subtitle: Text(formatMinutes(period.startMinutes)),
                      onTap: () => _pickPeriodTime(index, isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('结束'),
                      subtitle: Text(formatMinutes(period.endMinutes)),
                      onTap: () => _pickPeriodTime(index, isStart: false),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 单独页面里逐节调整开始与结束时间，保存后再整体回传给设置入口。
  Future<void> _pickPeriodTime(int index, {required bool isStart}) async {
    final period = _periodTimes[index];
    final initialMinutes = isStart ? period.startMinutes : period.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60),
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
    final minutes = (picked.hour * 60) + picked.minute;
    setState(() {
      _periodTimes[index] = isStart
          ? period.copyWith(startMinutes: minutes)
          : period.copyWith(endMinutes: minutes);
    });
  }
}
