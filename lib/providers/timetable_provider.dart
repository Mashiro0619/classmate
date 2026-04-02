import 'package:flutter/foundation.dart';

import '../data/timetable_storage.dart';
import '../models/timetable_models.dart';

/// 负责承载当前激活课表、当前周数，以及所有持久化写回操作。
class TimetableProvider extends ChangeNotifier {
  TimetableProvider({TimetableStorage? storage}) : _storage = storage ?? TimetableStorage();

  final TimetableStorage _storage;

  AppData _appData = buildSampleAppData();
  int _selectedWeek = 1;
  bool _isLoaded = false;
  String? _storagePath;

  bool get isLoaded => _isLoaded;
  List<TimetableData> get timetables => _appData.timetables;
  int get selectedWeek => _selectedWeek;
  String? get storagePath => _storagePath;

  TimetableData get activeTimetable => _appData.timetables.firstWhere(
    (item) => item.id == _appData.activeTimetableId,
    orElse: () => _appData.timetables.first,
  );

  /// 应用启动时加载 JSON 文件，没有文件时写入示例数据。
  Future<void> load() async {
    _storagePath = await _storage.filePath();
    final fileData = await _storage.load();
    if (fileData != null) {
      _appData = fileData;
    } else {
      await _save();
    }
    _selectedWeek = currentWeekFor(activeTimetable.config);
    _isLoaded = true;
    notifyListeners();
  }

  /// 切换当前活跃课表，并重置到该课表对应的当前周。
  Future<void> switchTimetable(String timetableId) async {
    if (_appData.activeTimetableId == timetableId) {
      return;
    }
    _appData = AppData(
      activeTimetableId: timetableId,
      timetables: _appData.timetables,
    );
    _selectedWeek = currentWeekFor(activeTimetable.config);
    await _saveAndNotify();
  }

  /// 只更新当前周，不触发文件写入，避免滑动切周时频繁落盘。
  Future<void> setSelectedWeek(int week) async {
    final maxWeek = activeTimetable.config.totalWeeks;
    final nextWeek = week.clamp(1, maxWeek);
    if (_selectedWeek == nextWeek) {
      return;
    }
    _selectedWeek = nextWeek;
    notifyListeners();
  }

  /// 保存课表设置，包括可编辑的节次时间段。
  Future<void> updateTimetableConfig(TimetableConfig config) async {
    final updated = _appData.timetables
        .map((item) => item.id == activeTimetable.id ? item.copyWith(config: config) : item)
        .toList();
    _appData = AppData(
      activeTimetableId: _appData.activeTimetableId,
      timetables: updated,
    );
    _selectedWeek = _selectedWeek.clamp(1, config.totalWeeks);
    await _saveAndNotify();
  }

  /// 新增或覆盖一门课程。
  Future<void> saveCourse(CourseItem course) async {
    final courses = [...activeTimetable.courses];
    final index = courses.indexWhere((item) => item.id == course.id);
    if (index >= 0) {
      courses[index] = course;
    } else {
      courses.add(course);
    }
    await _replaceActiveTimetable(activeTimetable.copyWith(courses: courses));
  }

  /// 删除指定课程。
  Future<void> deleteCourse(String courseId) async {
    final courses = activeTimetable.courses.where((item) => item.id != courseId).toList();
    await _replaceActiveTimetable(activeTimetable.copyWith(courses: courses));
  }

  /// 新建课表时沿用 JSON 存储结构，保证多课表数据格式一致。
  Future<void> addTimetable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = buildDefaultPeriodTimes();
    final timetable = TimetableData(
      id: 'table_$now',
      config: TimetableConfig(
        name: '新课表',
        startDate: DateTime.now(),
        totalWeeks: 18,
        dailyPeriods: 10,
        periodTimes: defaults.take(10).toList(),
      ),
      courses: const [],
    );

    _appData = AppData(
      activeTimetableId: timetable.id,
      timetables: [..._appData.timetables, timetable],
    );
    _selectedWeek = 1;
    await _saveAndNotify();
  }

  Future<void> _replaceActiveTimetable(TimetableData timetable) async {
    final updated = _appData.timetables
        .map((item) => item.id == timetable.id ? timetable : item)
        .toList();
    _appData = AppData(
      activeTimetableId: _appData.activeTimetableId,
      timetables: updated,
    );
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.save(_appData);
  }
}
