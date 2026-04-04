import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/timetable_storage.dart';
import '../models/timetable_models.dart';

enum AppImportMode { replaceAll, addAll }

enum TimetableImportMode { addAsNew, replaceActive }

/// 负责承载当前活跃课表、当前周数，以及所有持久化写回操作。
class TimetableProvider extends ChangeNotifier {
  TimetableProvider({TimetableStorage? storage})
    : _storage = storage ?? TimetableStorage();

  final TimetableStorage _storage;

  AppData _appData = buildInitialAppData(buildDefaultPeriodTimes());
  int _selectedWeek = 1;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _storagePath;

  bool get isLoaded => _isLoaded;
  bool get hasTimetables => _appData.timetables.isNotEmpty;
  bool get hasPeriodTimeSets => _appData.periodTimeSets.isNotEmpty;
  List<TimetableData> get timetables => _appData.timetables;
  List<PeriodTimeSet> get periodTimeSets => _appData.periodTimeSets;
  int get selectedWeek => _selectedWeek;
  String? get storagePath => _storagePath;
  bool get closeCoursePopupOnOutsideTap =>
      _appData.closeCoursePopupOnOutsideTap;
  String get localeCode => _appData.localeCode;

  TimetableData? get activeTimetableOrNull {
    if (_appData.timetables.isEmpty) {
      return null;
    }
    for (final item in _appData.timetables) {
      if (item.id == _appData.activeTimetableId) {
        return item;
      }
    }
    return _appData.timetables.first;
  }

  TimetableData get activeTimetable =>
      activeTimetableOrNull ?? _createFallbackTimetable();

  PeriodTimeSet? get activePeriodTimeSetOrNull {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      return _appData.periodTimeSets.isEmpty
          ? null
          : _appData.periodTimeSets.first;
    }
    return periodTimeSetForId(timetable.config.periodTimeSetId);
  }

  PeriodTimeSet get activePeriodTimeSet =>
      activePeriodTimeSetOrNull ?? _createFallbackPeriodTimeSet();

  /// 应用启动后异步加载数据：即便存储失败，也至少先把界面渲染出来。
  Future<void> load() async {
    if (_isLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    try {
      final fileData = await _storage.load();
      if (fileData != null) {
        _appData = _normalizeImportedAppData(fileData);
      } else {
        _appData = await _buildDefaultAppData();
        await _save();
      }
      _storagePath = await _storage.filePath();
    } catch (_) {
      _appData = await _buildDefaultAppData();
      try {
        _storagePath = await _storage.filePath();
      } catch (_) {
        _storagePath = null;
      }
    } finally {
      _selectedWeek = activeTimetableOrNull == null
          ? 1
          : currentWeekFor(activeTimetable.config);
      _isLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  PeriodTimeSet? periodTimeSetForId(String id) {
    for (final item in _appData.periodTimeSets) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<TimetableData> timetablesUsingPeriodTimeSet(String periodTimeSetId) {
    return _appData.timetables
        .where((item) => item.config.periodTimeSetId == periodTimeSetId)
        .toList();
  }

  int dailyPeriodsForTimetable(TimetableData timetable) {
    return periodTimeSetForId(
          timetable.config.periodTimeSetId,
        )?.periodTimes.length ??
        1;
  }

  List<CoursePeriodTime> periodTimesForTimetable(TimetableData timetable) {
    return periodTimeSetForId(timetable.config.periodTimeSetId)?.periodTimes ??
        const [];
  }

  /// 切换当前活跃课表，并重置到该课表对应的当前周。
  Future<void> switchTimetable(String timetableId) async {
    if (_appData.activeTimetableId == timetableId) {
      return;
    }
    if (!_appData.timetables.any((item) => item.id == timetableId)) {
      return;
    }
    _appData = _appData.copyWith(activeTimetableId: timetableId);
    _selectedWeek = currentWeekFor(activeTimetable.config);
    await _saveAndNotify();
  }

  /// 只更新当前周，不触发文件写入，避免滑动切周时频繁落盘。
  Future<void> setSelectedWeek(int week) async {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      _selectedWeek = 1;
      notifyListeners();
      return;
    }
    final maxWeek = timetable.config.totalWeeks;
    final nextWeek = week.clamp(1, maxWeek);
    if (_selectedWeek == nextWeek) {
      return;
    }
    _selectedWeek = nextWeek;
    notifyListeners();
  }

  /// 保存课表设置。
  Future<void> updateTimetableConfig(TimetableConfig config) async {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      return;
    }
    final periodTimeSetId =
        periodTimeSetForId(config.periodTimeSetId)?.id ??
        activePeriodTimeSet.id;
    final updated = _appData.timetables
        .map(
          (item) => item.id == timetable.id
              ? item.copyWith(
                  config: config.copyWith(periodTimeSetId: periodTimeSetId),
                )
              : item,
        )
        .toList();
    _appData = _appData.copyWith(timetables: updated);
    _selectedWeek = _selectedWeek.clamp(1, config.totalWeeks);
    await _saveAndNotify();
  }

  /// 新增或覆盖一门课程。
  Future<void> saveCourse(CourseItem course) async {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      return;
    }
    final courses = [...timetable.courses];
    final index = courses.indexWhere((item) => item.id == course.id);
    if (index >= 0) {
      courses[index] = course;
    } else {
      courses.add(course);
    }
    await _replaceActiveTimetable(timetable.copyWith(courses: courses));
  }

  /// 删除指定课程。
  Future<void> deleteCourse(String courseId) async {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      return;
    }
    final courses = timetable.courses
        .where((item) => item.id != courseId)
        .toList();
    final filteredPrefs = Map<String, String>.from(
      _appData.conflictDisplayCourseIds,
    )..removeWhere((_, value) => value == courseId);
    _appData = _appData.copyWith(
      timetables: _appData.timetables
          .map(
            (item) => item.id == timetable.id
                ? item.copyWith(courses: courses)
                : item,
          )
          .toList(),
      conflictDisplayCourseIds: filteredPrefs,
    );
    await _saveAndNotify();
  }

  /// 新建课表时沿用共享节次时间集结构。
  Future<void> addTimetable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fallbackSet =
        activePeriodTimeSetOrNull ?? _createFallbackPeriodTimeSet();
    final timetable = TimetableData(
      id: 'table_$now',
      config: TimetableConfig(
        name: newTimetableName(localeCode: _appData.localeCode),
        startDate: DateTime.now(),
        totalWeeks: 18,
        periodTimeSetId: fallbackSet.id,
      ),
      courses: const [],
    );

    _appData = _appData.copyWith(
      activeTimetableId: timetable.id,
      timetables: [..._appData.timetables, timetable],
    );
    _selectedWeek = 1;
    await _saveAndNotify();
  }

  Future<void> deleteTimetable(String timetableId) async {
    if (!_appData.timetables.any((item) => item.id == timetableId)) {
      return;
    }
    final remaining = _appData.timetables
        .where((item) => item.id != timetableId)
        .toList();
    final nextActiveId =
        remaining.any((item) => item.id == _appData.activeTimetableId)
        ? _appData.activeTimetableId
        : remaining.isEmpty
        ? ''
        : remaining.first.id;
    final remainingCourseIds = remaining
        .expand((item) => item.courses)
        .map((item) => item.id)
        .toSet();
    final filteredPrefs = Map<String, String>.from(
      _appData.conflictDisplayCourseIds,
    )..removeWhere((_, value) => !remainingCourseIds.contains(value));
    _appData = _appData.copyWith(
      activeTimetableId: nextActiveId,
      timetables: remaining,
      conflictDisplayCourseIds: filteredPrefs,
    );
    _selectedWeek = activeTimetableOrNull == null
        ? 1
        : currentWeekFor(activeTimetable.config);
    await _saveAndNotify();
  }

  Future<PeriodTimeSet> addPeriodTimeSet({
    String? name,
    List<CoursePeriodTime>? periodTimes,
  }) async {
    final existingIds = _appData.periodTimeSets.map((item) => item.id).toSet();
    final nextId = _nextPeriodTimeSetId(existingIds);
    final normalizedTimes = buildPeriodTimesForCount(
      periodTimes == null || periodTimes.isEmpty ? 10 : periodTimes.length,
      source: periodTimes,
    );
    final nextSet = PeriodTimeSet(
      id: nextId,
      name: (name == null || name.trim().isEmpty)
          ? newPeriodTimeSetName(localeCode: _appData.localeCode)
          : name.trim(),
      periodTimes: normalizedTimes,
    );
    _appData = _appData.copyWith(
      periodTimeSets: [..._appData.periodTimeSets, nextSet],
    );
    await _saveAndNotify();
    return nextSet;
  }

  Future<void> updatePeriodTimeSet(PeriodTimeSet periodTimeSet) async {
    final normalized = _normalizePeriodTimeSet(periodTimeSet);
    final index = _appData.periodTimeSets.indexWhere(
      (item) => item.id == normalized.id,
    );
    if (index < 0) {
      return;
    }
    final updated = [..._appData.periodTimeSets];
    updated[index] = normalized;
    _appData = _appData.copyWith(periodTimeSets: updated);
    await _saveAndNotify();
  }

  Future<void> deletePeriodTimeSet(String periodTimeSetId) async {
    final usingTimetables = timetablesUsingPeriodTimeSet(periodTimeSetId);
    if (usingTimetables.isNotEmpty) {
      throw FormatException(
        periodTimeSetInUseMessage(
          usingTimetables.length,
          localeCode: _appData.localeCode,
        ),
      );
    }
    final remaining = _appData.periodTimeSets
        .where((item) => item.id != periodTimeSetId)
        .toList();
    _appData = _appData.copyWith(periodTimeSets: remaining);
    await _saveAndNotify();
  }

  Future<void> assignPeriodTimeSetToTimetable(
    String timetableId,
    String periodTimeSetId,
  ) async {
    if (periodTimeSetForId(periodTimeSetId) == null) {
      return;
    }
    final updated = _appData.timetables
        .map(
          (item) => item.id == timetableId
              ? item.copyWith(
                  config: item.config.copyWith(
                    periodTimeSetId: periodTimeSetId,
                  ),
                )
              : item,
        )
        .toList();
    _appData = _appData.copyWith(timetables: updated);
    await _saveAndNotify();
  }

  String? displayedCourseIdForConflict(String conflictKey) =>
      _appData.conflictDisplayCourseIds[conflictKey];

  Future<void> setDisplayedCourseForConflict(
    String conflictKey,
    String courseId,
  ) async {
    final updated = Map<String, String>.from(_appData.conflictDisplayCourseIds)
      ..[conflictKey] = courseId;
    _appData = _appData.copyWith(conflictDisplayCourseIds: updated);
    await _saveAndNotify();
  }

  /// 导出完整应用数据，包含全部课表与全部节次时间集。
  String exportAppDataJson() => encodeAppDataEnvelope(_appData);

  /// 导出指定课表，以及它们依赖的节次时间集。
  String exportSelectedTimetablesJson(List<String> timetableIds) {
    final selectedIdSet = timetableIds.toSet();
    final selectedTimetables = _appData.timetables
        .where((item) => selectedIdSet.contains(item.id))
        .toList();
    if (selectedTimetables.isEmpty) {
      throw FormatException(
        selectAtLeastOneTimetableMessage(localeCode: _appData.localeCode),
      );
    }
    final periodTimeSetIds = selectedTimetables
        .map((item) => item.config.periodTimeSetId)
        .toSet();
    final linkedSets = _appData.periodTimeSets
        .where((item) => periodTimeSetIds.contains(item.id))
        .toList();
    return encodeTimetableDataEnvelope(
      TimetableExportData(
        timetables: selectedTimetables,
        periodTimeSets: linkedSets,
      ),
    );
  }

  /// 兼容保留：导出当前课表。
  String exportActiveTimetableJson() {
    final timetable = activeTimetableOrNull;
    if (timetable == null) {
      throw FormatException(
        noExportableTimetableMessage(localeCode: _appData.localeCode),
      );
    }
    return exportSelectedTimetablesJson([timetable.id]);
  }

  /// 导出当前课表的节次时间模板。
  String exportActivePeriodTimesJson() =>
      encodePeriodTimesEnvelope(activePeriodTimeSet.periodTimes);

  List<TimetableData> previewImportTimetables(String source) {
    return _decodeImportCandidate(source).timetables;
  }

  Future<int> importSelectedTimetablesJson(
    String source, {
    required List<String> timetableIds,
    required TimetableImportMode mode,
  }) async {
    final imported = _decodeImportCandidate(source);
    final selectedIdSet = timetableIds.toSet();
    final selectedTimetables = imported.timetables
        .where((item) => selectedIdSet.contains(item.id))
        .toList();
    if (selectedTimetables.isEmpty) {
      throw FormatException(
        selectAtLeastOneTimetableMessage(localeCode: _appData.localeCode),
      );
    }

    if (mode == TimetableImportMode.replaceActive) {
      if (selectedTimetables.length != 1) {
        throw FormatException(
          replaceActiveRequiresSingleTimetableMessage(
            localeCode: _appData.localeCode,
          ),
        );
      }
      final current = activeTimetableOrNull;
      if (current == null) {
        throw FormatException(
          noActiveTimetableToReplaceMessage(localeCode: _appData.localeCode),
        );
      }
      final selected = selectedTimetables.first;
      final importedSet = imported.periodTimeSets.firstWhere(
        (item) => item.id == selected.config.periodTimeSetId,
        orElse: () => _createFallbackPeriodTimeSet(),
      );
      final existingSetIds = _appData.periodTimeSets
          .map((item) => item.id)
          .toSet();
      final copiedSet = _copyImportedPeriodTimeSetWithUniqueId(
        importedSet,
        existingSetIds,
      );
      final replaced = selected.copyWith(
        id: current.id,
        config: selected.config.copyWith(periodTimeSetId: copiedSet.id),
      );
      final updatedTimetables = _appData.timetables
          .map((item) => item.id == current.id ? replaced : item)
          .toList();
      _appData = _appData.copyWith(
        activeTimetableId: current.id,
        timetables: updatedTimetables,
        periodTimeSets: [..._appData.periodTimeSets, copiedSet],
      );
      _selectedWeek = currentWeekFor(replaced.config);
      await _saveAndNotify();
      return 1;
    }

    final neededSetIds = selectedTimetables
        .map((item) => item.config.periodTimeSetId)
        .toSet();
    final selectedSets = imported.periodTimeSets
        .where((item) => neededSetIds.contains(item.id))
        .toList();
    final existingSetIds = _appData.periodTimeSets
        .map((item) => item.id)
        .toSet();
    final importedSetIdMap = <String, String>{};
    final appendedSets = selectedSets.map((item) {
      final copied = _copyImportedPeriodTimeSetWithUniqueId(
        item,
        existingSetIds,
      );
      importedSetIdMap[item.id] = copied.id;
      return copied;
    }).toList();

    final existingTimetableIds = _appData.timetables
        .map((item) => item.id)
        .toSet();
    final appendedTimetables = selectedTimetables.map((item) {
      final mappedSetId =
          importedSetIdMap[item.config.periodTimeSetId] ??
          item.config.periodTimeSetId;
      return _copyImportedTimetableWithUniqueId(
        item.copyWith(
          config: item.config.copyWith(periodTimeSetId: mappedSetId),
        ),
        existingTimetableIds,
      );
    }).toList();

    _appData = _appData.copyWith(
      activeTimetableId: appendedTimetables.isEmpty
          ? _appData.activeTimetableId
          : appendedTimetables.last.id,
      timetables: [..._appData.timetables, ...appendedTimetables],
      periodTimeSets: [..._appData.periodTimeSets, ...appendedSets],
    );
    _selectedWeek = appendedTimetables.isEmpty
        ? _selectedWeek
        : currentWeekFor(appendedTimetables.last.config);
    await _saveAndNotify();
    return appendedTimetables.length;
  }

  /// 导入完整应用数据；覆盖模式会直接替换当前数据，新增模式则把导入课表与节次时间集合并进现有数据。
  Future<int> importAppDataJson(
    String source, {
    required AppImportMode mode,
  }) async {
    final imported = _normalizeImportedAppData(decodeAppDataEnvelope(source));
    if (mode == AppImportMode.replaceAll) {
      _appData = imported;
      _selectedWeek = activeTimetableOrNull == null
          ? 1
          : currentWeekFor(activeTimetable.config);
      await _saveAndNotify();
      return imported.timetables.length;
    }

    return importSelectedTimetablesJson(
      source,
      timetableIds: imported.timetables.map((item) => item.id).toList(),
      mode: TimetableImportMode.addAsNew,
    );
  }

  /// 导入单个课表；可作为新课表加入，也可直接覆盖当前激活课表。
  Future<String> importTimetableJson(
    String source, {
    required TimetableImportMode mode,
  }) async {
    final imported = _decodeImportCandidate(source);
    final selected = imported.timetables.first;
    await importSelectedTimetablesJson(
      source,
      timetableIds: [selected.id],
      mode: mode,
    );
    return selected.config.name;
  }

  /// 读取节次时间模板；是否真正保存由调用方决定，这样页面可以先作为草稿预览。
  List<CoursePeriodTime> importPeriodTimesJson(String source) {
    final periodTimes = decodePeriodTimesEnvelope(
      source,
      localeCode: _appData.localeCode,
    );
    if (periodTimes.isEmpty) {
      throw FormatException(
        noPeriodTimesInImportMessage(localeCode: _appData.localeCode),
      );
    }
    return List.generate(
      periodTimes.length,
      (index) => periodTimes[index].copyWith(index: index + 1),
    );
  }

  Future<AppData> _buildDefaultAppData() async {
    try {
      final source = await rootBundle.loadString(defaultPeriodTimesAssetPath);
      final periodTimes = importPeriodTimesJson(source);
      return _normalizeImportedAppData(
        buildInitialAppData(periodTimes, localeCode: _appData.localeCode),
      );
    } catch (_) {
      return _normalizeImportedAppData(
        buildInitialAppData(
          buildDefaultPeriodTimes(),
          localeCode: _appData.localeCode,
        ),
      );
    }
  }

  Future<void> updateCloseCoursePopupOnOutsideTap(bool value) async {
    if (_appData.closeCoursePopupOnOutsideTap == value) {
      return;
    }
    _appData = _appData.copyWith(closeCoursePopupOnOutsideTap: value);
    await _saveAndNotify();
  }

  Future<void> updateLocaleCode(String localeCode) async {
    final normalized = normalizeLocaleCode(localeCode);
    if (_appData.localeCode == normalized) {
      return;
    }
    _appData = _appData.copyWith(localeCode: normalized);
    await _saveAndNotify();
  }

  Future<void> _replaceActiveTimetable(TimetableData timetable) async {
    final updated = _appData.timetables
        .map((item) => item.id == timetable.id ? timetable : item)
        .toList();
    _appData = _appData.copyWith(timetables: updated);
    await _saveAndNotify();
  }

  AppData _normalizeImportedAppData(AppData data) {
    final normalizedSets = <PeriodTimeSet>[];
    final normalizedSetIds = <String>{};
    for (final item in data.periodTimeSets) {
      final normalized = _normalizePeriodTimeSet(item);
      final nextId =
          normalized.id.trim().isEmpty ||
              normalizedSetIds.contains(normalized.id)
          ? _nextPeriodTimeSetId(normalizedSetIds)
          : normalized.id;
      normalizedSetIds.add(nextId);
      normalizedSets.add(normalized.copyWith(id: nextId));
    }

    final normalizedTimetables = <TimetableData>[];
    for (final item in data.timetables) {
      var periodTimeSetId = item.config.periodTimeSetId.trim();
      if (periodTimeSetId.isEmpty ||
          !normalizedSetIds.contains(periodTimeSetId)) {
        final fallbackSet = _createImportedFallbackPeriodTimeSet(
          item,
          normalizedSetIds,
        );
        normalizedSets.add(fallbackSet);
        normalizedSetIds.add(fallbackSet.id);
        periodTimeSetId = fallbackSet.id;
      }
      normalizedTimetables.add(
        item.copyWith(
          config: item.config.copyWith(
            totalWeeks: item.config.totalWeeks < 1 ? 1 : item.config.totalWeeks,
            periodTimeSetId: periodTimeSetId,
          ),
        ),
      );
    }

    final activeId =
        normalizedTimetables.any((item) => item.id == data.activeTimetableId)
        ? data.activeTimetableId
        : normalizedTimetables.isEmpty
        ? ''
        : normalizedTimetables.first.id;
    final remainingCourseIds = normalizedTimetables
        .expand((item) => item.courses)
        .map((item) => item.id)
        .toSet();
    final filteredPrefs = Map<String, String>.from(
      data.conflictDisplayCourseIds,
    )..removeWhere((_, value) => !remainingCourseIds.contains(value));
    return data.copyWith(
      activeTimetableId: activeId,
      timetables: normalizedTimetables,
      periodTimeSets: normalizedSets,
      conflictDisplayCourseIds: filteredPrefs,
      localeCode: normalizeLocaleCode(data.localeCode),
    );
  }

  TimetableExportData _decodeImportCandidate(String source) {
    final envelope = ImportExportEnvelope.decode(source);
    if (envelope.version > importExportVersion) {
      throw FormatException(
        importFileVersionUnsupportedMessage(localeCode: _appData.localeCode),
      );
    }
    switch (envelope.schema) {
      case timetableDataSchema:
        return _normalizeImportedTimetableExport(
          TimetableExportData.fromJson(
            envelope.data,
            localeCode: _appData.localeCode,
          ),
        );
      case appDataSchema:
        final appData = _normalizeImportedAppData(
          AppData.fromJson({
            ...envelope.data,
            'localeCode': _appData.localeCode,
          }),
        );
        return TimetableExportData(
          timetables: appData.timetables,
          periodTimeSets: appData.periodTimeSets,
        );
      default:
        throw FormatException(
          importFileTypeMismatchMessage(localeCode: _appData.localeCode),
        );
    }
  }

  TimetableExportData _normalizeImportedTimetableExport(
    TimetableExportData data,
  ) {
    final normalizedSets = <PeriodTimeSet>[];
    final setIds = <String>{};
    for (final item in data.periodTimeSets) {
      final normalized = _normalizePeriodTimeSet(item);
      final nextId =
          normalized.id.trim().isEmpty || setIds.contains(normalized.id)
          ? _nextPeriodTimeSetId(setIds)
          : normalized.id;
      setIds.add(nextId);
      normalizedSets.add(normalized.copyWith(id: nextId));
    }

    final normalizedTimetables = <TimetableData>[];
    for (final item in data.timetables) {
      var timetable = item.copyWith(
        config: item.config.copyWith(
          totalWeeks: item.config.totalWeeks < 1 ? 1 : item.config.totalWeeks,
        ),
      );
      if (normalizedSets.isEmpty ||
          !setIds.contains(timetable.config.periodTimeSetId)) {
        final fallbackSet = _createImportedFallbackPeriodTimeSet(
          timetable,
          setIds,
        );
        normalizedSets.add(fallbackSet);
        setIds.add(fallbackSet.id);
        timetable = timetable.copyWith(
          config: timetable.config.copyWith(periodTimeSetId: fallbackSet.id),
        );
      }
      normalizedTimetables.add(timetable);
    }

    return TimetableExportData(
      timetables: normalizedTimetables,
      periodTimeSets: normalizedSets,
    );
  }

  PeriodTimeSet _createImportedFallbackPeriodTimeSet(
    TimetableData timetable,
    Set<String> existingIds,
  ) {
    final fallbackId = _nextPeriodTimeSetId(existingIds);
    return PeriodTimeSet(
      id: fallbackId,
      name: importedPeriodTimeSetName(
        timetable.config.name,
        localeCode: _appData.localeCode,
      ),
      periodTimes: buildPeriodTimesForCount(10),
    );
  }

  PeriodTimeSet _copyImportedPeriodTimeSetWithUniqueId(
    PeriodTimeSet periodTimeSet,
    Set<String> existingIds,
  ) {
    var nextId = periodTimeSet.id.trim();
    if (nextId.isEmpty || existingIds.contains(nextId)) {
      nextId = _nextPeriodTimeSetId(existingIds);
    }
    existingIds.add(nextId);
    return _normalizePeriodTimeSet(periodTimeSet.copyWith(id: nextId));
  }

  TimetableData _copyImportedTimetableWithUniqueId(
    TimetableData timetable,
    Set<String> existingIds,
  ) {
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

  String _nextPeriodTimeSetId(Set<String> existingIds) {
    var stamp = DateTime.now().microsecondsSinceEpoch;
    var candidate = 'period_set_$stamp';
    while (existingIds.contains(candidate)) {
      stamp += 1;
      candidate = 'period_set_$stamp';
    }
    return candidate;
  }

  PeriodTimeSet _normalizePeriodTimeSet(PeriodTimeSet periodTimeSet) {
    final normalizedTimes = buildPeriodTimesForCount(
      periodTimeSet.periodTimes.isEmpty ? 1 : periodTimeSet.periodTimes.length,
      source: periodTimeSet.periodTimes,
    );
    return periodTimeSet.copyWith(
      name: periodTimeSet.name.trim().isEmpty
          ? periodTimeSetFallbackName(localeCode: _appData.localeCode)
          : periodTimeSet.name.trim(),
      periodTimes: normalizedTimes,
    );
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    _appData = _normalizeImportedAppData(_appData);
    await _storage.save(_appData);
  }

  TimetableData _createFallbackTimetable() {
    return TimetableData(
      id: '',
      config: TimetableConfig(
        name: emptyTimetableName(localeCode: _appData.localeCode),
        startDate: DateTime.now(),
        totalWeeks: 1,
        periodTimeSetId: '',
      ),
      courses: const [],
    );
  }

  PeriodTimeSet _createFallbackPeriodTimeSet() {
    return PeriodTimeSet(
      id: '',
      name: defaultPeriodTimeSetName(localeCode: _appData.localeCode),
      periodTimes: const [
        CoursePeriodTime(
          index: 1,
          startMinutes: 8 * 60,
          endMinutes: (8 * 60) + 45,
        ),
      ],
    );
  }
}
