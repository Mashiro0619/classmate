import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../widgets/course_editor_sheet.dart';
import '../widgets/timetable_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  bool _controllerInitialized = false;
  double? _draggingSliderValue;

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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.name),
                Text('第 $week 周', style: Theme.of(context).textTheme.labelMedium),
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
            onPressed: () => _openEditor(context, provider, weekday: 1),
            icon: const Icon(Icons.add),
            label: const Text('添加课程'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton.outlined(
                      onPressed: week > 1 ? () => _animateToWeek(provider, week - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '学期开始：${config.startDate.year}-${config.startDate.month.toString().padLeft(2, '0')}-${config.startDate.day.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Slider(
                            value: (_draggingSliderValue ?? week.toDouble()).clamp(1, config.totalWeeks.toDouble()),
                            min: 1,
                            max: config.totalWeeks.toDouble(),
                            divisions: config.totalWeeks > 1 ? config.totalWeeks - 1 : 1,
                            label: '第 ${(_draggingSliderValue ?? week.toDouble()).round()} 周',
                            onChanged: (value) {
                              setState(() => _draggingSliderValue = value);
                            },
                            onChangeEnd: (value) {
                              setState(() => _draggingSliderValue = null);
                              _animateToWeek(provider, value.round());
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: week < config.totalWeeks ? () => _animateToWeek(provider, week + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: config.totalWeeks,
                  onPageChanged: (index) => provider.setSelectedWeek(index + 1),
                  itemBuilder: (context, index) {
                    final pageWeek = index + 1;
                    final weekStart = startOfWeekFor(config, pageWeek);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: TimetableGrid(
                        timetable: timetable,
                        weekDateStart: weekStart,
                        onCourseTap: (course) => _openEditor(context, provider, course: course),
                        onEmptySlotTap: (weekday) => _openEditor(context, provider, weekday: weekday),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  Future<void> _editSettings(
    BuildContext context,
    TimetableProvider provider,
    TimetableConfig config,
  ) async {
    final nameController = TextEditingController(text: config.name);
    final weeksController = TextEditingController(text: config.totalWeeks.toString());
    final periodsController = TextEditingController(text: config.dailyPeriods.toString());
    DateTime selectedDate = config.startDate;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('课表设置'),
              content: SingleChildScrollView(
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
                  ],
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
                    final periods = buildDefaultPeriodTimes().take(normalizedPeriods).toList();
                    await provider.updateTimetableConfig(
                      config.copyWith(
                        name: nameController.text.trim().isEmpty ? config.name : nameController.text.trim(),
                        startDate: selectedDate,
                        totalWeeks: totalWeeks < 1 ? 1 : totalWeeks,
                        dailyPeriods: normalizedPeriods,
                        periodTimes: periods,
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
