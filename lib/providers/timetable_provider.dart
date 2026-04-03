import 'package:flutter/foundation.dart';

import '../data/timetable_storage.dart';
import '../models/timetable_models.dart';

enum AppImportMode { replaceAll, addAll }

enum TimetableImportMode { addAsNew, replaceActive }

/// 负责承载当前激活课表、当前周数，以及所有持久化写回操作。
class TimetableProvider extends ChangeNotifier {
  TimetableProvider({TimetableStorage? storage}) : _storage = storage ?? TimetableStorage();

  final TimetableStorage _storage;

  AppData _appData = buildSampleAppData();
  int _selectedWeek = 1;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _storagePath;

  bool get isLoaded => _isLoaded;
  List<TimetableData> get timetables => _appData.timetables;
  int get selectedWeek => _selectedWeek;
  String? get storagePath => _storagePath;

  TimetableData get activeTimetable => _appData.timetables.firstWhere(
    (item) => item.id == _appData.activeTimetableId,
    orElse: () => _appData.timetables.first,
  );

  /// 应用启动后异步加载数据：即便存储失败，也至少先把界面渲染出来。
  Future<void> load() async {
    if (_isLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    try {
      final fileData = await _storage.load();
      if (fileData != null) {
        _appData = fileData;
      } else {
        await _save();
      }
      _storagePath = await _storage.filePath();
    } catch (_) {
      _appData = buildSampleAppData();
      try {
        _storagePath = await _storage.filePath();
      } catch (_) {
        _storagePath = null;
      }
    } finally {
      _selectedWeek = currentWeekFor(activeTimetable.config);
      _isLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
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

  /// 导出完整应用数据，包含全部课表与各自节次时间。
  String exportAppDataJson() => encodeAppDataEnvelope(_appData);

  /// 导出当前课表，节次时间会跟随课表配置一并导出。
  String exportActiveTimetableJson() => encodeTimetableDataEnvelope(activeTimetable);

  /// 导出当前课表的节次时间模板。
  String exportActivePeriodTimesJson() => encodePeriodTimesEnvelope(activeTimetable.config.periodTimes);

  /// 导入完整应用数据；覆盖模式会直接替换当前数据，新增模式则把导入课表附加到现有列表末尾。
  Future<int> importAppDataJson(String source, {required AppImportMode mode}) async {
    final imported = _normalizeImportedAppData(decodeAppDataEnvelope(source));
    if (mode == AppImportMode.replaceAll) {
      _appData = imported;
      _selectedWeek = currentWeekFor(activeTimetable.config);
      await _saveAndNotify();
      return imported.timetables.length;
    }

    final existingIds = _appData.timetables.map((item) => item.id).toSet();
    final appended = imported.timetables
        .map((item) => _copyImportedTimetableWithUniqueId(item, existingIds))
        .toList();
    _appData = AppData(
      activeTimetableId: _appData.activeTimetableId,
      timetables: [..._appData.timetables, ...appended],
    );
    await _saveAndNotify();
    return appended.length;
  }

  /// 导入单个课表；可作为新课表加入，也可直接覆盖当前激活课表。
  Future<String> importTimetableJson(String source, {required TimetableImportMode mode}) async {
    final imported = _normalizeTimetable(decodeTimetableDataEnvelope(source));
    if (mode == TimetableImportMode.replaceActive) {
      final replaced = imported.copyWith(id: activeTimetable.id);
      final updated = _appData.timetables
          .map((item) => item.id == activeTimetable.id ? replaced : item)
          .toList();
      _appData = AppData(
        activeTimetableId: activeTimetable.id,
        timetables: updated,
      );
      _selectedWeek = currentWeekFor(replaced.config);
      await _saveAndNotify();
      return replaced.config.name;
    }

    final existingIds = _appData.timetables.map((item) => item.id).toSet();
    final appended = _copyImportedTimetableWithUniqueId(imported, existingIds);
    _appData = AppData(
      activeTimetableId: appended.id,
      timetables: [..._appData.timetables, appended],
    );
    _selectedWeek = currentWeekFor(appended.config);
    await _saveAndNotify();
    return appended.config.name;
  }

  /// 读取节次时间模板；是否真正保存由调用方决定，这样页面可以先作为草稿预览。
  List<CoursePeriodTime> importPeriodTimesJson(String source) {
    final periodTimes = decodePeriodTimesEnvelope(source);
    if (periodTimes.isEmpty) {
      throw const FormatException('导入文件中没有节次时间');
    }
    return List.generate(
      periodTimes.length,
      (index) => periodTimes[index].copyWith(index: index + 1),
    );
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

  TimetableData _normalizeTimetable(TimetableData timetable) {
    final defaults = buildDefaultPeriodTimes();
    final fallbackCount = timetable.config.dailyPeriods.clamp(1, defaults.length);
    final normalizedPeriodTimes = timetable.config.periodTimes.isEmpty
        ? defaults.take(fallbackCount).toList()
        : List.generate(
            timetable.config.periodTimes.length,
            (index) => timetable.config.periodTimes[index].copyWith(index: index + 1),
          );
    return timetable.copyWith(
      config: timetable.config.copyWith(
        dailyPeriods: normalizedPeriodTimes.length,
        periodTimes: normalizedPeriodTimes,
      ),
    );
  }

  AppData _normalizeImportedAppData(AppData data) {
    if (data.timetables.isEmpty) {
      throw const FormatException('导入文件中没有课表数据');
    }
    final normalizedTimetables = data.timetables.map(_normalizeTimetable).toList();
    final activeId = normalizedTimetables.any((item) => item.id == data.activeTimetableId)
        ? data.activeTimetableId
        : normalizedTimetables.first.id;
    return AppData(activeTimetableId: activeId, timetables: normalizedTimetables);
  }

  TimetableData _copyImportedTimetableWithUniqueId(TimetableData timetable, Set<String> existingIds) {
    var nextId = timetable.id.trim();
    if (nextId.isEmpty || existingIds.contains(nextId)) {
      nextId = _nextImportedTimetableId(existingIds);
    }
    existingIds.add(nextId);
    return timetable.copyWith(id: nextId);
  }

  String _nextImportedTimetableId(Set<String> existingIds) {
    var stamp = DateTime.now().microsecondsSinceEpoch;
    var candidate = 'table_import_$stamp';
    while (existingIds.contains(candidate)) {
      stamp += 1;
      candidate = 'table_import_$stamp';
    }
    return candidate;
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.save(_appData);
  }
}
