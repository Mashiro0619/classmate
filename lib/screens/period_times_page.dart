import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';

enum _PeriodTimesMenuAction { importTemplate, exportTemplate, saveTemplate, deleteSet }

/// 节次时间编辑独立成页面，直接修改共享节次时间集。
class PeriodTimesPage extends StatefulWidget {
  const PeriodTimesPage({
    super.key,
    required this.periodTimeSetId,
  });

  final String periodTimeSetId;

  @override
  State<PeriodTimesPage> createState() => _PeriodTimesPageState();
}

class _PeriodTimesPageState extends State<PeriodTimesPage> {
  late final TextEditingController _nameController;
  late List<CoursePeriodTime> _periodTimes;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      final provider = context.read<TimetableProvider>();
      final periodTimeSet = provider.periodTimeSetForId(widget.periodTimeSetId);
      if (periodTimeSet != null) {
        _nameController.text = periodTimeSet.name;
        _periodTimes = periodTimeSet.periodTimes.map((item) => item.copyWith()).toList();
      } else {
        _nameController.text = '节次时间';
        _periodTimes = buildPeriodTimesForCount(10);
      }
      _loading = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              PopupMenuDivider(),
              PopupMenuItem(
                value: _PeriodTimesMenuAction.deleteSet,
                child: Text('删除节次时间'),
              ),
            ],
          ),
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '节次时间名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _periodTimes.length; index++) _buildPeriodCard(index),
          OutlinedButton.icon(
            onPressed: _addPeriod,
            icon: const Icon(Icons.add),
            label: const Text('增加一节'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodCard(int index) {
    final period = _periodTimes[index];
    final previous = index == 0 ? null : _periodTimes[index - 1];
    final duration = period.endMinutes - period.startMinutes;
    final gap = previous == null ? null : period.startMinutes - previous.endMinutes;
    final invalid = duration <= 0 || (previous != null && gap! < 0);

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('第 ${period.index} 节', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_periodTimes.length > 1)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '删除本节',
                    onPressed: () => _removePeriod(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _TimeCell(
                    label: '开始',
                    value: formatMinutes(period.startMinutes),
                    onTap: () => _pickPeriodTime(index, isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeCell(
                    label: '结束',
                    value: formatMinutes(period.endMinutes),
                    onTap: () => _pickPeriodTime(index, isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(label: '时长 ${duration > 0 ? duration : 0} 分钟'),
                if (gap != null) _MetaChip(label: '与上一节间隔 ${gap > 0 ? gap : 0} 分钟'),
              ],
            ),
            if (invalid) ...[
              const SizedBox(height: 10),
              Text(
                duration <= 0 ? '结束时间必须晚于开始时间' : '当前节次与上一节时间重叠',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
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
      case _PeriodTimesMenuAction.deleteSet:
        await _deleteSet();
        return;
    }
  }

  void _addPeriod() {
    setState(() {
      _periodTimes = buildPeriodTimesForCount(_periodTimes.length + 1, source: _periodTimes);
    });
  }

  void _removePeriod(int index) {
    setState(() {
      final next = [..._periodTimes]..removeAt(index);
      _periodTimes = List.generate(next.length, (itemIndex) => next[itemIndex].copyWith(index: itemIndex + 1));
    });
  }

  Future<void> _save() async {
    final provider = context.read<TimetableProvider>();
    final normalized = buildPeriodTimesForCount(_periodTimes.length, source: _periodTimes);
    await provider.updatePeriodTimeSet(
      PeriodTimeSet(
        id: widget.periodTimeSetId,
        name: _nameController.text.trim(),
        periodTimes: normalized,
      ),
    );
    if (mounted) {
      _showMessage('已保存节次时间');
    }
  }

  Future<void> _deleteSet() async {
    final provider = context.read<TimetableProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除节次时间'),
          content: Text('确认删除“${_nameController.text.trim().isEmpty ? '当前节次时间' : _nameController.text.trim()}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await provider.deletePeriodTimeSet(widget.periodTimeSetId);
      if (mounted) {
        navigator.pop(true);
      }
    } on FormatException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _importTemplate() async {
    final provider = context.read<TimetableProvider>();
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
      final imported = provider.importPeriodTimesJson(decoded);
      if (imported.isEmpty) {
        throw const FormatException('导入文件中没有节次时间');
      }
      setState(() {
        _periodTimes = imported;
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
    try {
      final content = encodePeriodTimesEnvelope(_periodTimes);
      final location = await getSaveLocation(suggestedName: 'classmate_period_times.json');
      if (location == null) {
        await _shareTemplate();
        if (mounted) {
          _showMessage('系统未返回保存位置，已改用分享导出');
        }
        return;
      }
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(content)),
        mimeType: 'application/json',
        name: 'classmate_period_times.json',
      );
      await file.saveTo(location.path);
      if (mounted) {
        _showMessage('已保存到 ${location.path}');
      }
    } catch (_) {
      await _shareTemplate();
      if (mounted) {
        _showMessage('保存失败，已改用分享导出');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 单独页面里逐节调整开始与结束时间，保存后直接写回共享资源。
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

class _TimeCell extends StatelessWidget {
  const _TimeCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
