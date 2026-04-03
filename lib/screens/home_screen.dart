import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../widgets/course_details_sheet.dart';
import '../widgets/course_editor_sheet.dart';
import '../widgets/timetable_grid.dart';
import 'settings_page.dart';

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

        final timetable = provider.activeTimetableOrNull;
        if (timetable == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Classmate')),
            body: _EmptyTimetableState(
              onCreate: provider.addTimetable,
              onImport: () => _importTimetableData(context, provider),
            ),
          );
        }

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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
                      value: provider,
                      child: const SettingsPage(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
                tooltip: '设置',
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
                            leading: Icon(item.id == timetable.id ? Icons.check_circle : Icons.calendar_view_week),
                            title: Text(item.config.name),
                            subtitle: Text(item.id == timetable.id ? '当前课表 · 共 ${item.config.totalWeeks} 周' : '点击切换 · 共 ${item.config.totalWeeks} 周'),
                            trailing: IconButton(
                              tooltip: '编辑课表',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                await _openTimetableItemDialog(context, provider, item);
                              },
                            ),
                            onTap: () async {
                              if (item.id == timetable.id) {
                                Navigator.of(context).pop();
                                return;
                              }
                              await provider.switchTimetable(item.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
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
          body: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _jumpWeekBy(provider, -1),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () => _jumpWeekBy(provider, 1),
            },
            child: Focus(
              autofocus: true,
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.invertedStylus,
                  },
                ),
                child: PageView.builder(
                  controller: _pageController!,
                  itemCount: config.totalWeeks,
                  onPageChanged: (index) => provider.setSelectedWeek(index + 1),
                  itemBuilder: (context, index) {
                    final pageWeek = index + 1;
                    final weekStart = startOfWeekFor(config, pageWeek);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 8, 0, 12),
                      child: TimetableGrid(
                        timetable: timetable,
                        periodTimes: provider.periodTimesForTimetable(timetable),
                        weekDateStart: weekStart,
                        selectedWeek: pageWeek,
                        displayedCourseIdForConflict: provider.displayedCourseIdForConflict,
                        onCourseTap: (info) => _openDetails(context, provider, info),
                        onEmptySlotTap: (weekday) => _openEditor(context, provider, weekday: weekday),
                      ),
                    );
                  },
                ),
              ),
            ),
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

  Future<void> _jumpWeekBy(TimetableProvider provider, int offset) async {
    final timetable = provider.activeTimetableOrNull;
    if (timetable == null || offset == 0) {
      return;
    }
    final targetWeek = (provider.selectedWeek + offset).clamp(1, timetable.config.totalWeeks);
    if (targetWeek == provider.selectedWeek) {
      return;
    }
    await _animateToWeek(provider, targetWeek);
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
    TimetableCourseTapInfo info,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildAdaptiveBottomSheet(
        sheetContext,
        maxWidth: 860,
        child: CourseDetailsSheet(
          course: info.course,
          conflictCourses: info.isFullConflict ? info.courses : const [],
          onEdit: () {
            Navigator.of(sheetContext).pop();
            _openEditor(context, provider, course: info.course);
          },
          onSelectDisplayedCourse: !info.isFullConflict || info.conflictKey == null
              ? null
              : (course) async {
                  await provider.setDisplayedCourseForConflict(info.conflictKey!, course.id);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
          onEditConflictCourse: !info.isFullConflict
              ? null
              : (course) {
                  Navigator.of(sheetContext).pop();
                  _openEditor(context, provider, course: course);
                },
        ),
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
    final periodTimes = provider.activeTimetableOrNull == null
        ? buildDefaultPeriodTimes()
        : provider.periodTimesForTimetable(provider.activeTimetable);
    final totalWeeks = provider.activeTimetableOrNull?.config.totalWeeks ?? 18;
    final result = await showModalBottomSheet<CourseEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildAdaptiveBottomSheet(
        sheetContext,
        maxWidth: 920,
        child: CourseEditorSheet(
          periodTimes: periodTimes,
          totalWeeks: totalWeeks,
          initialCourse: course,
          dayOfWeek: weekday ?? course?.dayOfWeek ?? 1,
        ),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$week'),
                  ),
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

  Future<void> _openTimetableItemDialog(
    BuildContext context,
    TimetableProvider provider,
    TimetableData timetable,
  ) async {
    final nameController = TextEditingController(text: timetable.config.name);
    final weeksController = TextEditingController(text: timetable.config.totalWeeks.toString());
    final navigator = Navigator.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('课表'),
          content: SizedBox(
            width: 420,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'),
              child: const Text('删除'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (result == 'save') {
      final totalWeeks = int.tryParse(weeksController.text) ?? timetable.config.totalWeeks;
      await provider.switchTimetable(timetable.id);
      await provider.updateTimetableConfig(
        timetable.config.copyWith(
          name: nameController.text.trim().isEmpty ? timetable.config.name : nameController.text.trim(),
          totalWeeks: totalWeeks < 1 ? 1 : totalWeeks,
        ),
      );
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
    }
    if (result == 'delete') {
      if (!mounted) {
        nameController.dispose();
        weeksController.dispose();
        return;
      }
      final confirmed = await showDialog<bool>(
        context: this.context,
        builder: (context) {
          return AlertDialog(
            title: const Text('删除课表'),
            content: Text('确认删除“${timetable.config.name}”吗？'),
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
      if (confirmed == true) {
        await provider.deleteTimetable(timetable.id);
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }
      }
    }
    nameController.dispose();
    weeksController.dispose();
  }

  Future<void> _importTimetableData(BuildContext context, TimetableProvider provider) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const SettingsPage(),
        ),
      ),
    );
    if (result == null) {
      return;
    }
  }

  Widget _buildAdaptiveBottomSheet(
    BuildContext context, {
    required Widget child,
    required double maxWidth,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLike = width >= 900;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktopLike ? maxWidth : width,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmptyTimetableState extends StatelessWidget {
  const _EmptyTimetableState({
    required this.onCreate,
    required this.onImport,
  });

  final Future<void> Function() onCreate;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 48),
            const SizedBox(height: 12),
            Text('当前没有课表', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('可以新建一个课表，或从 JSON 文件导入已有课表。', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('新建课表'),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('导入课表'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
