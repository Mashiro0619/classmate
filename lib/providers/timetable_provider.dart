import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timetable_models.dart';

class TimetableProvider extends ChangeNotifier {
  static const _storageKey = 'classmate_app_data';

  AppData _appData = buildSampleAppData();
  int _selectedWeek = 1;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<TimetableData> get timetables => _appData.timetables;
  int get selectedWeek => _selectedWeek;

  TimetableData get activeTimetable => _appData.timetables.firstWhere(
    (item) => item.id == _appData.activeTimetableId,
    orElse: () => _appData.timetables.first,
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      _appData = AppData.decode(raw);
    } else {
      await _save();
    }
    _selectedWeek = currentWeekFor(activeTimetable.config);
    _isLoaded = true;
    notifyListeners();
  }

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

  Future<void> setSelectedWeek(int week) async {
    final maxWeek = activeTimetable.config.totalWeeks;
    final nextWeek = week.clamp(1, maxWeek);
    if (_selectedWeek == nextWeek) {
      return;
    }
    _selectedWeek = nextWeek;
    notifyListeners();
  }

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

  Future<void> deleteCourse(String courseId) async {
    final courses = activeTimetable.courses.where((item) => item.id != courseId).toList();
    await _replaceActiveTimetable(activeTimetable.copyWith(courses: courses));
  }

  Future<void> addTimetable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timetable = TimetableData(
      id: 'table_$now',
      config: TimetableConfig(
        name: '新课表',
        startDate: DateTime.now(),
        totalWeeks: 18,
        dailyPeriods: 10,
        periodTimes: buildDefaultPeriodTimes().take(10).toList(),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _appData.encode());
  }
}
