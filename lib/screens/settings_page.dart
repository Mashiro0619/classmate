import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../services/export_service.dart';
import 'period_times_page.dart';

enum _DataAction {
  importTimetables,
  exportTimetablesShare,
  exportTimetablesSave,
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
                onTap: () => _pickStartDate(provider, timetable.config),
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('节次时间集'),
                subtitle: Text(selectedSet == null ? '暂无可用节次时间' : '${selectedSet.name} · ${selectedSet.periodTimes.length} 节'),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickPeriodTimeSet(provider, timetable.config),
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
                subtitle: const Text('github.com/Mashiro0619/classmate'),
                onTap: _openGithubRepo,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPeriodTimeSet(TimetableProvider provider, TimetableConfig config) async {
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
    if (result == null || result == _selectedPeriodTimeSetId) {
      return;
    }
    setState(() => _selectedPeriodTimeSetId = result);
    await provider.updateTimetableConfig(config.copyWith(periodTimeSetId: result));
  }

  Future<void> _pickStartDate(TimetableProvider provider, TimetableConfig config) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked == null || picked == _selectedDate) {
      return;
    }
    setState(() => _selectedDate = picked);
    await provider.updateTimetableConfig(config.copyWith(startDate: picked));
  }

  Future<void> _openGithubRepo() async {
    final uri = Uri.parse('https://github.com/Mashiro0619/classmate');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage('无法打开 GitHub 仓库链接');
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
                title: const Text('导入课表'),
                subtitle: const Text('支持单个或多个课表文件'),
                onTap: () => Navigator.of(context).pop(_DataAction.importTimetables),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('分享课表文件'),
                subtitle: const Text('先选择一个或多个课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportTimetablesShare),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('保存课表文件'),
                subtitle: const Text('先选择一个或多个课表'),
                onTap: () => Navigator.of(context).pop(_DataAction.exportTimetablesSave),
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
      case _DataAction.importTimetables:
        await _importTimetables(provider);
        return;
      case _DataAction.exportTimetablesShare:
        await _exportTimetables(provider, share: true);
        return;
      case _DataAction.exportTimetablesSave:
        await _exportTimetables(provider, share: false);
        return;
    }
  }

  Future<void> _exportTimetables(TimetableProvider provider, {required bool share}) async {
    final activeId = provider.activeTimetableOrNull?.id;
    final selectedIds = await _pickTimetableIds(
      timetables: provider.timetables,
      title: '选择要导出的课表',
      confirmText: share ? '分享' : '保存',
      initialSelectedIds: activeId == null ? const [] : [activeId],
    );
    if (selectedIds == null || selectedIds.isEmpty) {
      return;
    }
    try {
      final content = provider.exportSelectedTimetablesJson(selectedIds);
      const fileName = 'classmate_timetables.json';
      if (share) {
        await _shareJson(fileName, content);
      } else {
        await _saveJsonToFile(fileName, content);
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('导出失败，请稍后重试');
      }
    }
  }

  Future<void> _importTimetables(TimetableProvider provider) async {
    final source = await _pickJsonSource();
    if (source == null || !mounted) {
      return;
    }

    List<TimetableData> candidates;
    try {
      candidates = provider.previewImportTimetables(source);
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    } catch (_) {
      _showMessage('导入失败，请检查文件内容');
      return;
    }

    if (candidates.isEmpty) {
      _showMessage('导入文件中没有可用课表');
      return;
    }

    final selectedIds = candidates.length == 1
        ? [candidates.first.id]
        : await _pickTimetableIds(
            timetables: candidates,
            title: '选择要导入的课表',
            confirmText: '导入',
            initialSelectedIds: candidates.map((item) => item.id).toList(),
          );
    if (selectedIds == null || selectedIds.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    var mode = TimetableImportMode.addAsNew;
    if (selectedIds.length == 1 && provider.activeTimetableOrNull != null) {
      final pickedMode = await showDialog<TimetableImportMode>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('导入课表'),
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
      if (pickedMode == null) {
        return;
      }
      mode = pickedMode;
    }

    try {
      final count = await provider.importSelectedTimetablesJson(
        source,
        timetableIds: selectedIds,
        mode: mode,
      );
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

  Future<List<String>?> _pickTimetableIds({
    required List<TimetableData> timetables,
    required String title,
    required String confirmText,
    List<String> initialSelectedIds = const [],
  }) {
    final draft = <String>{
      ...initialSelectedIds.where((id) => timetables.any((item) => item.id == id)),
    };
    if (draft.isEmpty && timetables.isNotEmpty) {
      draft.add(timetables.first.id);
    }
    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
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
                                ..addAll(timetables.map((item) => item.id));
                            }),
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: () => setState(draft.clear),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: timetables.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final timetable = timetables[index];
                          final selected = draft.contains(timetable.id);
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            tileColor: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
                            title: Text(timetable.config.name),
                            subtitle: Text('${timetable.courses.length} 门课程'),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  draft.remove(timetable.id);
                                } else {
                                  draft.add(timetable.id);
                                }
                              });
                            },
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
                  onPressed: draft.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                            timetables.where((item) => draft.contains(item.id)).map((item) => item.id).toList(),
                          ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        );
      },
    );
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
          message: '请在系统设置中打开文件访问权限，然后返回重试导出。',
          confirmText: '打开设置',
        );
        if (openSettings == true) {
          await _exportService.openSettings();
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
