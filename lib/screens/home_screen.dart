import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../widgets/course_details_sheet.dart';
import '../widgets/course_editor_sheet.dart';
import '../widgets/timetable_grid.dart';
import 'period_times_page.dart';

enum _DataAction {
  importApp,
  importTimetable,
  exportAppShare,
  exportAppSave,
  exportTimetableShare,
  exportTimetableSave,
}

/// 主页面负责三件事：
/// 1. 通过 PageView 提供左右滑动切周
/// 2. 提供多课表切换与课表设置入口
/// 3. 统一管理课程详情弹窗与编辑弹窗的切换流程
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController? _pageController;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final timetable = provider.activeTimetable;
        final config = timetable.config;
        final week = provider.selectedWeek;
        _ensurePageController(week);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _showWeekPicker(context, provider, config.totalWeeks),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('第 $week 周', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _openEditor(context, provider),
                icon: const Icon(Icons.add),
                tooltip: '添加课程',
              ),
              IconButton(
                onPressed: () => _editSettings(context, provider, config),
                icon: const Icon(Icons.tune),
                tooltip: '课表设置',
              ),
            ],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  const ListTile(title: Text('多课表切换')),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final item in provider.timetables)
                          ListTile(
                            selected: item.id == timetable.id,
                            leading: const Icon(Icons.calendar_view_week),
                            title: Text(item.config.name),
                            subtitle: Text('共 ${item.config.totalWeeks} 周'),
                            onTap: () async {
                              Navigator.of(context).pop();
                              await provider.switchTimetable(item.id);
                            },
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: provider.addTimetable,
                      icon: const Icon(Icons.add),
                      label: const Text('新建课表'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: PageView.builder(
            controller: _pageController!,
            itemCount: config.totalWeeks,
            onPageChanged: (index) => provider.setSelectedWeek(index + 1),
            itemBuilder: (context, index) {
              final pageWeek = index + 1;
              final weekStart = startOfWeekFor(config, pageWeek);
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: TimetableGrid(
                  timetable: timetable,
                  weekDateStart: weekStart,
                  selectedWeek: pageWeek,
                  onCourseTap: (course) => _openDetails(context, provider, course),
                  onEmptySlotTap: (weekday) => _openEditor(context, provider, weekday: weekday),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Provider 改成异步加载后，需要在首帧拿到真实周数时再创建或校正 PageController。
  void _ensurePageController(int week) {
    final targetPage = week - 1;
    if (_pageController == null) {
      _pageController = PageController(initialPage: targetPage);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) {
        return;
      }
      final currentPage = _pageController!.page?.round() ?? targetPage;
      if (currentPage != targetPage) {
        _pageController!.jumpToPage(targetPage);
      }
    });
  }

  /// 统一处理带动画的周跳转，确保与滑动体验一致。
  Future<void> _animateToWeek(TimetableProvider provider, int week) async {
    final controller = _pageController;
    final targetPage = week - 1;
    if (controller == null || !controller.hasClients) {
      await provider.setSelectedWeek(week);
      return;
    }
    await controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// 点击课程后先看详情，再由详情页进入编辑模式。
  Future<void> _openDetails(
    BuildContext context,
    TimetableProvider provider,
    CourseItem course,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CourseDetailsSheet(
        course: course,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          _openEditor(context, provider, course: course);
        },
      ),
    );
  }

  /// 课程编辑恢复为底部弹窗；上课日和周次都在这里维护，但周次通过二级弹窗选择。
  Future<void> _openEditor(
    BuildContext context,
    TimetableProvider provider, {
    CourseItem? course,
    int? weekday,
  }) async {
    final result = await showModalBottomSheet<CourseEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CourseEditorSheet(
        periodTimes: provider.activeTimetable.config.periodTimes,
        totalWeeks: provider.activeTimetable.config.totalWeeks,
        initialCourse: course,
        dayOfWeek: weekday ?? course?.dayOfWeek ?? 1,
      ),
    );

    if (result == null) {
      return;
    }
    if (result.delete && course != null) {
      await provider.deleteCourse(course.id);
      return;
    }
    if (result.course != null) {
      await provider.saveCourse(result.course!);
    }
  }

  /// 顶部周数入口使用快捷弹窗，便于快速跳到任意周。
  Future<void> _showWeekPicker(
    BuildContext context,
    TimetableProvider provider,
    int totalWeeks,
  ) async {
    final week = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('快捷跳转周数'),
          content: SizedBox(
            width: 320,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: totalWeeks,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final week = index + 1;
                return FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(week),
                  child: Text('$week 周'),
                );
              },
            ),
          ),
        );
      },
    );

    if (week != null) {
      await _animateToWeek(provider, week);
    }
  }

  /// 设置弹窗只保留课表基础信息，节次时间改到独立页面中处理。
  Future<void> _editSettings(
    BuildContext context,
    TimetableProvider provider,
    TimetableConfig config,
  ) async {
    final nameController = TextEditingController(text: config.name);
    final weeksController = TextEditingController(text: config.totalWeeks.toString());
    final periodsController = TextEditingController(text: config.dailyPeriods.toString());
    DateTime selectedDate = config.startDate;
    var editablePeriodTimes = config.periodTimes.map((item) => item.copyWith()).toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('课表设置'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: '课表名称')),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weeksController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '总周数'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: periodsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '每日总节次'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('开学日期'),
                        subtitle: Text(
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: selectedDate,
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('节次时间设置'),
                        subtitle: Text('当前共 ${_normalizeDailyPeriods(periodsController.text, config.dailyPeriods)} 节，点击进入独立页面编辑'),
                        onTap: () async {
                          final nextPeriodTimes = _buildNormalizedPeriodTimes(
                            editablePeriodTimes,
                            _normalizeDailyPeriods(periodsController.text, config.dailyPeriods),
                          );
                          final result = await Navigator.of(dialogContext).push<List<CoursePeriodTime>>(
                            MaterialPageRoute(
                              builder: (_) => PeriodTimesPage(periodTimes: nextPeriodTimes),
                            ),
                          );
                          if (result != null) {
                            setState(() => editablePeriodTimes = result);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.import_export),
                        title: const Text('导入导出数据'),
                        subtitle: const Text('导入整包/单课表，或导出当前课表与全部课表'),
                        onTap: () => _showDataActions(dialogContext, provider),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final totalWeeks = int.tryParse(weeksController.text) ?? config.totalWeeks;
                    final normalizedPeriods = _normalizeDailyPeriods(periodsController.text, config.dailyPeriods);
                    final nextPeriodTimes = _buildNormalizedPeriodTimes(editablePeriodTimes, normalizedPeriods);
                    await provider.updateTimetableConfig(
                      config.copyWith(
                        name: nameController.text.trim().isEmpty ? config.name : nameController.text.trim(),
                        startDate: selectedDate,
                        totalWeeks: totalWeeks < 1 ? 1 : totalWeeks,
                        dailyPeriods: normalizedPeriods,
                        periodTimes: nextPeriodTimes,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    weeksController.dispose();
    periodsController.dispose();
  }

  Future<void> _showDataActions(BuildContext context, TimetableProvider provider) async {
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
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case _DataAction.importApp:
        await _importAppData(context, provider);
        return;
      case _DataAction.importTimetable:
        await _importTimetableData(context, provider);
        return;
      case _DataAction.exportAppShare:
        await _shareJson('classmate_app_data.json', provider.exportAppDataJson());
        return;
      case _DataAction.exportAppSave:
        await _saveJsonToFile(context, 'classmate_app_data.json', provider.exportAppDataJson());
        return;
      case _DataAction.exportTimetableShare:
        await _shareJson('classmate_timetable.json', provider.exportActiveTimetableJson());
        return;
      case _DataAction.exportTimetableSave:
        await _saveJsonToFile(context, 'classmate_timetable.json', provider.exportActiveTimetableJson());
        return;
    }
  }

  Future<void> _importAppData(BuildContext context, TimetableProvider provider) async {
    final source = await _pickJsonSource();
    if (source == null || !context.mounted) {
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
      if (context.mounted) {
        _showMessage(context, '已导入 $count 个课表');
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, '导入失败，请检查文件内容');
      }
    }
  }

  Future<void> _importTimetableData(BuildContext context, TimetableProvider provider) async {
    final source = await _pickJsonSource();
    if (source == null || !context.mounted) {
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
      if (context.mounted) {
        _showMessage(context, '已导入课表：$name');
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, '导入失败，请检查文件内容');
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
    await SharePlus.instance.share(
      ShareParams(
        text: content,
        subject: fileName,
      ),
    );
  }

  Future<void> _saveJsonToFile(BuildContext context, String fileName, String content) async {
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) {
      return;
    }
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      name: fileName,
    );
    await file.saveTo(location.path);
    if (context.mounted) {
      _showMessage(context, '已保存到 ${location.path}');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 节次数量变化时，统一在这里做裁切与默认补全，避免多个页面各自维护一套规则。
  List<CoursePeriodTime> _buildNormalizedPeriodTimes(List<CoursePeriodTime> source, int dailyPeriods) {
    final defaults = buildDefaultPeriodTimes();
    return List.generate(dailyPeriods, (index) {
      if (index < source.length) {
        return source[index].copyWith(index: index + 1);
      }
      final fallback = defaults[index];
      return fallback.copyWith(index: index + 1);
    });
  }

  int _normalizeDailyPeriods(String value, int fallback) {
    final parsed = int.tryParse(value) ?? fallback;
    return parsed.clamp(1, buildDefaultPeriodTimes().length);
  }
}
