import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timetable_models.dart';

enum _PeriodTimesMenuAction { importTemplate, exportTemplate, saveTemplate }

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
          PopupMenuButton<_PeriodTimesMenuAction>(
            tooltip: '导入导出',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PeriodTimesMenuAction.importTemplate,
                child: Text('导入节次模板'),
              ),
              PopupMenuItem(
                value: _PeriodTimesMenuAction.exportTemplate,
                child: Text('分享节次模板'),
              ),
              PopupMenuItem(
                value: _PeriodTimesMenuAction.saveTemplate,
                child: Text('保存模板到文件'),
              ),
            ],
          ),
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

  Future<void> _handleMenuAction(_PeriodTimesMenuAction action) async {
    switch (action) {
      case _PeriodTimesMenuAction.importTemplate:
        await _importTemplate();
        return;
      case _PeriodTimesMenuAction.exportTemplate:
        await _shareTemplate();
        return;
      case _PeriodTimesMenuAction.saveTemplate:
        await _saveTemplateToFile();
        return;
    }
  }

  Future<void> _importTemplate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return;
    }
    try {
      final decoded = utf8.decode(bytes);
      final imported = decodePeriodTimesEnvelope(decoded);
      if (imported.isEmpty) {
        throw const FormatException('导入文件中没有节次时间');
      }
      setState(() {
        _periodTimes = List.generate(
          imported.length,
          (index) => imported[index].copyWith(index: index + 1),
        );
      });
      _showMessage('已导入 ${_periodTimes.length} 条节次时间');
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('导入失败，请检查文件内容');
    }
  }

  Future<void> _shareTemplate() async {
    final content = encodePeriodTimesEnvelope(_periodTimes);
    await SharePlus.instance.share(
      ShareParams(
        text: content,
        subject: 'classmate 节次时间模板',
      ),
    );
  }

  Future<void> _saveTemplateToFile() async {
    final location = await getSaveLocation(suggestedName: 'classmate_period_times.json');
    if (location == null) {
      return;
    }
    final content = encodePeriodTimesEnvelope(_periodTimes);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      name: 'classmate_period_times.json',
    );
    await file.saveTo(location.path);
    if (mounted) {
      _showMessage('已保存到 ${location.path}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
