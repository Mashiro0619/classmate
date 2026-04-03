import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../services/export_service.dart';
import 'period_times_page.dart';

enum _DataAction {
  importApp,
  importTimetable,
  exportAppShare,
  exportAppSave,
  exportTimetableShare,
  exportTimetableSave,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _exportService = ExportService();

  String? _editingTimetableId;
  late DateTime _selectedDate;
  late String _selectedPeriodTimeSetId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TimetableProvider>();
    final timetable = provider.activeTimetableOrNull;
    if (timetable == null) {
      return;
    }
    if (_editingTimetableId == timetable.id) {
      return;
    }
    _editingTimetableId = timetable.id;
    _selectedDate = timetable.config.startDate;
    _selectedPeriodTimeSetId = timetable.config.periodTimeSetId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        final timetable = provider.activeTimetableOrNull;
        if (timetable == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('设置')),
            body: const Center(child: Text('当前没有可设置的课表')),
          );
        }
        final selectedSet = provider.periodTimeSetForId(_selectedPeriodTimeSetId) ?? provider.activePeriodTimeSetOrNull;
        return Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开学日期'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickStartDate,
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('节次时间集'),
                subtitle: Text(selectedSet == null ? '暂无可用节次时间' : '${selectedSet.name} · ${selectedSet.periodTimes.length} 节'),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickPeriodTimeSet(provider),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('编辑节次时间'),
                subtitle: Text(selectedSet == null ? '暂无可用节次时间' : '${selectedSet.name} · ${selectedSet.periodTimes.length} 节'),
                onTap: selectedSet == null ? null : () => _openPeriodTimePage(provider, selectedSet.id),
              ),
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('新建节次时间集'),
                subtitle: const Text('创建后可直接进入编辑页面'),
                onTap: () => _createPeriodTimeSet(provider),
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.import_export),
                title: const Text('导入导出数据'),
                subtitle: const Text('导入整包/单课表，或导出当前课表与全部课表'),
                onTap: () => _showDataActions(provider),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new),
                title: const Text('GitHub 仓库'),
                subtitle: const Text('TODO: 在这里填仓库链接'),
                onTap: () => _showMessage('请在 lib/screens/settings_page.dart 的 GitHub 仓库列表项里替换链接'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPeriodTimeSet(TimetableProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择节次时间集'),
          content: SizedBox(
            width: 360,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: provider.periodTimeSets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.periodTimeSets[index];
                final selected = item.id == _selectedPeriodTimeSetId;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
                  title: Text(item.name),
                  subtitle: Text('${item.periodTimes.length} 节'),
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(item.id),
                );
              },
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _selectedPeriodTimeSetId = result);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveSettings(TimetableProvider provider, TimetableConfig config) async {
    await provider.updateTimetableConfig(
      config.copyWith(
        startDate: _selectedDate,
        periodTimeSetId: _selectedPeriodTimeSetId,
      ),
    );
    if (mounted) {
      _showMessage('已保存设置');
    }
  }

  Future<void> _openPeriodTimePage(TimetableProvider provider, String periodTimeSetId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: PeriodTimesPage(periodTimeSetId: periodTimeSetId),
        ),
      ),
    );
  }

  Future<void> _createPeriodTimeSet(TimetableProvider provider) async {
    final created = await provider.addPeriodTimeSet();
    if (!mounted) {
      return;
    }
    setState(() => _selectedPeriodTimeSetId = created.id);
    await _openPeriodTimePage(provider, created.id);
  }

  Future<void> _showDataActions(TimetableProvider provider) async {
    final action = await showModalBottomSheet<_DataAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('导入全部课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.importApp),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_outlined),
                title: const Text('导入单个课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.importTimetable),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('分享全部课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportAppShare),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('保存全部课表到文件'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportAppSave),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('分享当前课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportTimetableShare),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('保存当前课表到文件'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportTimetableSave),
              ),
            ],
          ),
        );
      },
    );
    if (action == null || !mounted) {
      return;
    }
    switch (action) {
      case _DataAction.importApp:
        await _importAppData(provider);
        return;
      case _DataAction.importTimetable:
        await _importTimetableData(provider);
        return;
      case _DataAction.exportAppShare:
        await _shareJson('classmate_app_data.json', provider.exportAppDataJson());
        return;
      case _DataAction.exportAppSave:
        await _saveJsonToFile('classmate_app_data.json', provider.exportAppDataJson());
        return;
      case _DataAction.exportTimetableShare:
        await _shareJson('classmate_timetable.json', provider.exportActiveTimetableJson());
        return;
      case _DataAction.exportTimetableSave:
        await _saveJsonToFile('classmate_timetable.json', provider.exportActiveTimetableJson());
        return;
    }
  }

  Future<void> _importAppData(TimetableProvider provider) async {
    final source = await _pickJsonSource();
    if (source == null || !mounted) {
      return;
    }
    final mode = await showDialog<AppImportMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入全部课表'),
          content: const Text('请选择导入方式'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(AppImportMode.addAll),
              child: const Text('新增到现有数据'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(AppImportMode.replaceAll),
              child: const Text('覆盖现有数据'),
            ),
          ],
        );
      },
    );
    if (mode == null) {
      return;
    }
    try {
      final count = await provider.importAppDataJson(source, mode: mode);
      if (mounted) {
        _showMessage('已导入 $count 个课表');
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('导入失败，请检查文件内容');
      }
    }
  }

  Future<void> _importTimetableData(TimetableProvider provider) async {
    final source = await _pickJsonSource();
    if (source == null || !mounted) {
      return;
    }
    final mode = await showDialog<TimetableImportMode>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入单个课表'),
          content: const Text('请选择导入方式'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(TimetableImportMode.addAsNew),
              child: const Text('作为新课表导入'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(TimetableImportMode.replaceActive),
              child: const Text('覆盖当前课表'),
            ),
          ],
        );
      },
    );
    if (mode == null) {
      return;
    }
    try {
      final name = await provider.importTimetableJson(source, mode: mode);
      if (mounted) {
        _showMessage('已导入课表：$name');
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('导入失败，请检查文件内容');
      }
    }
  }

  Future<String?> _pickJsonSource() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }
    return utf8.decode(bytes);
  }

  Future<void> _shareJson(String fileName, String content) async {
    await _exportService.shareFile(ExportPayload(fileName: fileName, content: content));
  }

  Future<void> _saveJsonToFile(String fileName, String content) async {
    final result = await _exportService.saveFile(ExportPayload(fileName: fileName, content: content));
    if (!mounted) {
      return;
    }

    switch (result.status) {
      case ExportSaveStatus.saved:
        _showMessage('已保存到 ${result.path ?? fileName}');
        return;
      case ExportSaveStatus.cancelled:
        _showMessage('已取消保存');
        return;
      case ExportSaveStatus.permissionDenied:
        final retry = await _showPermissionDialog(
          title: '文件保存受限',
          message: '当前系统未能完成文件保存。你可以重试，或改用文件分享。',
          confirmText: '重试保存',
        );
        if (retry == true && mounted) {
          await _saveJsonToFile(fileName, content);
        }
        return;
      case ExportSaveStatus.permissionPermanentlyDenied:
        final openSettings = await _showPermissionDialog(
          title: '文件保存受限',
          message: '请检查系统设置中的文件访问限制，然后返回重试导出。',
          confirmText: '打开设置',
        );
        if (openSettings == true && mounted) {
          _showMessage('请在系统设置中检查文件访问限制后重试');
        }
        return;
      case ExportSaveStatus.unsupported:
        final shouldShare = await _showFailureDialog(
          title: '浏览器下载受限',
          message: '当前浏览器不支持直接保存到本地文件。你可以检查浏览器下载权限，或改用分享文件。',
        );
        if (shouldShare == true) {
          await _shareJson(fileName, content);
          if (mounted) {
            _showMessage('已改用文件分享导出');
          }
        }
        return;
      case ExportSaveStatus.failed:
        final shouldShare = await _showFailureDialog(
          title: _exportService.isWindows ? '文件保存失败' : '文件保存受限',
          message: _exportService.isWindows
              ? '无法写入当前路径，可能是目标文件夹受系统保护、文件被占用，或当前路径不可写。'
              : '系统未能完成文件保存。你可以重试、检查系统设置，或改用文件分享。',
        );
        if (shouldShare == true) {
          await _shareJson(fileName, content);
          if (mounted) {
            _showMessage('已改用文件分享导出');
          }
        } else if (mounted) {
          _showMessage('保存失败，请稍后重试');
        }
        return;
    }
  }

  Future<bool?> _showPermissionDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showFailureDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('稍后再试'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('改用分享'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
