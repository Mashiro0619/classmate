import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../widgets/course_details_sheet.dart';
import '../widgets/course_editor_sheet.dart';
import '../widgets/timetable_grid.dart';

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
  late final PageController _pageController;
  bool _controllerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerInitialized) {
      return;
    }
    final provider = context.read<TimetableProvider>();
    _pageController = PageController(initialPage: provider.selectedWeek - 1);
    _controllerInitialized = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        _syncPageWithWeek(week);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showWeekPicker(context, provider, config.totalWeeks),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('第 $week 周', style: Theme.of(context).textTheme.titleMedium),
                        Text('点击快捷跳转', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(config.name, overflow: TextOverflow.ellipsis),
                      Text(
                        '开学：${config.startDate.year}-${config.startDate.month.toString().padLeft(2, '0')}-${config.startDate.day.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context, provider, weekday: week == 0 ? 1 : 1),
            icon: const Icon(Icons.add),
            label: const Text('添加课程'),
          ),
          body: PageView.builder(
            controller: _pageController,
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

  /// 当 provider 中的周数被其他操作修改时，同步 PageView 的页码。
  void _syncPageWithWeek(int week) {
    if (!_controllerInitialized) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final currentPage = (_pageController.page ?? _pageController.initialPage.toDouble()).round();
      final targetPage = week - 1;
      if (currentPage != targetPage) {
        _pageController.jumpToPage(targetPage);
      }
    });
  }

  /// 统一处理带动画的周跳转，确保与滑动体验一致。
  Future<void> _animateToWeek(TimetableProvider provider, int week) async {
    final targetPage = week - 1;
    if (!_pageController.hasClients) {
      await provider.setSelectedWeek(week);
      return;
    }
    await _pageController.animateToPage(
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

  /// 编辑器仍复用原有 bottom sheet，只是入口不再直接暴露给课程点击。
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
        initialCourse: course,
        weekday: weekday ?? course?.weekday ?? 1,
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

  /// 课表设置中加入逐节时间编辑，不再只允许修改总节数。
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickPeriodTime(int index, {required bool isStart}) async {
              final period = editablePeriodTimes[index];
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
                editablePeriodTimes[index] = isStart
                    ? period.copyWith(startMinutes: minutes)
                    : period.copyWith(endMinutes: minutes);
              });
            }

            return AlertDialog(
              title: const Text('课表设置'),
              content: SizedBox(
                width: 560,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('节次时间表', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < editablePeriodTimes.length; i++)
                        Card.outlined(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                SizedBox(width: 48, child: Text('第 ${editablePeriodTimes[i].index} 节')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('开始'),
                                    subtitle: Text(formatMinutes(editablePeriodTimes[i].startMinutes)),
                                    onTap: () => pickPeriodTime(i, isStart: true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('结束'),
                                    subtitle: Text(formatMinutes(editablePeriodTimes[i].endMinutes)),
                                    onTap: () => pickPeriodTime(i, isStart: false),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                    final dailyPeriods = int.tryParse(periodsController.text) ?? config.dailyPeriods;
                    final normalizedPeriods = dailyPeriods.clamp(1, buildDefaultPeriodTimes().length);
                    final defaults = buildDefaultPeriodTimes();
                    final nextPeriodTimes = List.generate(normalizedPeriods, (index) {
                      if (index < editablePeriodTimes.length) {
                        return editablePeriodTimes[index].copyWith(index: index + 1);
                      }
                      final fallback = defaults[index];
                      return fallback.copyWith(index: index + 1);
                    });
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
}
