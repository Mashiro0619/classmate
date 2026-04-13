import 'dart:convert';
import 'dart:io';

import 'package:classmate/data/timetable_storage.dart';
import 'package:classmate/l10n/app_localizations.dart';
import 'package:classmate/main.dart' hide main;
import 'package:classmate/models/timetable_models.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:classmate/screens/home_screen.dart';
import 'package:classmate/widgets/course_details_sheet.dart';
import 'package:classmate/widgets/course_editor_sheet.dart';
import 'package:classmate/widgets/timetable_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 测试专用 JSON 存储实现，避免污染真实用户目录。
class TestTimetableStorage implements TimetableStorage {
  TestTimetableStorage(this.file);

  final File file;

  @override
  Future<void> save(AppData data) async {
    await file.writeAsString(data.encode());
  }

  @override
  Future<AppData?> load() async {
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return null;
    }
    return AppData.decode(content);
  }

  @override
  Future<String?> filePath() async => file.path;
}

/// 内存存储用于 widget 测试，避免依赖真实文件系统。
class MemoryTimetableStorage implements TimetableStorage {
  MemoryTimetableStorage({AppData? initialData})
    : _content = initialData?.encode();

  String? _content;

  @override
  Future<AppData?> load() async {
    if (_content == null || _content!.trim().isEmpty) {
      return null;
    }
    return AppData.decode(_content!);
  }

  @override
  Future<void> save(AppData data) async {
    _content = data.encode();
  }

  @override
  Future<String?> filePath() async => 'memory://classmate-test';
}

Widget _buildLocalizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('zh'), Locale('en')],
    home: Scaffold(body: child),
  );
}

AppData _buildTestAppData() {
  final periodTimes = buildDefaultPeriodTimes();
  final defaultSet = PeriodTimeSet(
    id: 'set1',
    name: '测试默认节次',
    periodTimes: periodTimes,
  );
  final shortSet = PeriodTimeSet(
    id: 'set2',
    name: '测试短节次',
    periodTimes: periodTimes.take(8).toList(),
  );
  final primaryTimetable = TimetableData(
    id: 'default',
    config: TimetableConfig(
      name: '测试课表A',
      startDate: DateTime(2026, 2, 23),
      totalWeeks: 18,
      periodTimeSetId: defaultSet.id,
    ),
    courses: [
      CourseItem(
        id: 'course1',
        name: '高等数学',
        teacher: '陈老师',
        location: 'A-201',
        dayOfWeek: 1,
        semesterWeeks: buildAllSemesterWeeks(18),
        periods: const [1, 2],
        startMinutes: periodTimes[0].startMinutes,
        endMinutes: periodTimes[1].endMinutes,
        timeRange: buildTimeRange(
          periodTimes[0].startMinutes,
          periodTimes[1].endMinutes,
        ),
        credit: 4,
        remarks: '记得带作业',
        customFields: const {'QQ群': '123456'},
      ),
    ],
  );
  final backupTimetable = TimetableData(
    id: 'backup',
    config: TimetableConfig(
      name: '测试课表B',
      startDate: DateTime(2026, 3, 2),
      totalWeeks: 16,
      periodTimeSetId: shortSet.id,
    ),
    courses: const [],
  );
  return AppData(
    activeTimetableId: primaryTimetable.id,
    timetables: [primaryTimetable, backupTimetable],
    periodTimeSets: [defaultSet, shortSet],
    privacyPolicyAcceptedVersion: currentPrivacyPolicyVersion,
  );
}

void main() {
  group('课表 JSON 存储', () {
    test('示例数据可以正确编码和解码', () {
      final data = _buildTestAppData();
      final encoded = data.encode();
      final decoded = AppData.decode(encoded);

      expect(decoded.activeTimetableId, data.activeTimetableId);
      expect(decoded.timetables.length, data.timetables.length);
      expect(decoded.timetables.first.config.name, '测试课表A');
    });

    test('旧 weekday 字段会兼容成 dayOfWeek，且周次默认为全学期语义', () {
      final legacyJson = {
        'id': 'legacy',
        'name': '旧数据课程',
        'teacher': '老师',
        'location': '教室',
        'weekday': 3,
        'periods': [1, 2],
        'startMinutes': 480,
        'endMinutes': 570,
        'timeRange': '08:00 - 09:30',
        'credit': 2,
        'remarks': '',
        'customFields': <String, dynamic>{},
      };
      final course = CourseItem.fromJson(legacyJson);

      expect(course.dayOfWeek, 3);
      expect(course.semesterWeeks, isEmpty);
      expect(course.toJson()['dayOfWeek'], 3);
      expect(course.toJson().containsKey('weekday'), isFalse);
    });

    test('时间段命中连续节次时能自动推导节次', () {
      final periods = buildDefaultPeriodTimes();
      final matched = matchPeriodsForTimeRange(
        periods,
        periods[0].startMinutes,
        periods[1].endMinutes,
      );

      expect(matched, [1, 2]);
    });

    test('时间段不命中节次时返回空列表', () {
      final periods = buildDefaultPeriodTimes();
      final matched = matchPeriodsForTimeRange(
        periods,
        periods[0].startMinutes + 5,
        periods[1].endMinutes,
      );

      expect(matched, isEmpty);
    });

    test('provider 会在首次加载时创建 JSON 文件并可再次读取', () async {
      final tempRoot = Directory.systemTemp.path;
      final file = File('$tempRoot/classmate_provider_test.json');
      if (await file.exists()) {
        await file.delete();
      }
      addTearDown(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });

      final firstProvider = TimetableProvider(
        storage: TestTimetableStorage(file),
      );
      await firstProvider.load();

      expect(await file.exists(), isTrue);
      expect(firstProvider.activeTimetable.config.name, '空课表');

      final secondProvider = TimetableProvider(
        storage: TestTimetableStorage(file),
      );
      await secondProvider.load();

      expect(secondProvider.timetables, isEmpty);
      expect(secondProvider.activeTimetable.config.name, '空课表');
    });

    test('导入导出包装结构可以正确编码与解码', () {
      final data = _buildTestAppData();
      final encoded = encodeAppDataEnvelope(data);
      final decoded = decodeAppDataEnvelope(encoded);

      expect(decoded.timetables.length, data.timetables.length);
      expect(decoded.activeTimetableId, data.activeTimetableId);
    });

    test('provider 支持导入单课表和节次模板', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      final exportedTimetable = provider.exportActiveTimetableJson();
      final originalCount = provider.timetables.length;
      await provider.importTimetableJson(
        exportedTimetable,
        mode: TimetableImportMode.addAsNew,
      );
      expect(provider.timetables.length, originalCount + 1);

      final exportedPeriodTimes = provider.exportActivePeriodTimesJson();
      final importedPeriodTimes = provider.importPeriodTimesJson(
        exportedPeriodTimes,
      );
      expect(
        importedPeriodTimes.length,
        provider.activePeriodTimeSet.periodTimes.length,
      );
      expect(importedPeriodTimes.first.index, 1);
    });

    test('旧数据会迁移出独立节次时间集', () {
      final legacy = AppData.decode(
        jsonEncode({
          'activeTimetableId': 'legacy_table',
          'timetables': [
            {
              'id': 'legacy_table',
              'config': {
                'name': '旧课表',
                'startDate': '2026-02-23T00:00:00.000',
                'totalWeeks': 18,
                'dailyPeriods': 4,
                'periodTimes': buildDefaultPeriodTimes()
                    .take(4)
                    .map((item) => item.toJson())
                    .toList(),
              },
              'courses': [],
            },
          ],
        }),
      );

      expect(legacy.periodTimeSets.length, 1);
      expect(legacy.timetables.first.config.periodTimeSetId, isNotEmpty);
      expect(legacy.periodTimeSets.first.periodTimes.length, 4);
    });

    test('共享节次时间集编辑会直接全局生效', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      final currentSet = provider.activePeriodTimeSet;
      await provider.assignPeriodTimeSetToTimetable('backup', currentSet.id);
      await provider.updatePeriodTimeSet(
        currentSet.copyWith(
          name: '全局新节次',
          periodTimes: buildPeriodTimesForCount(
            14,
            source: currentSet.periodTimes,
          ),
        ),
      );

      expect(provider.periodTimeSetForId(currentSet.id)?.name, '全局新节次');
      expect(
        provider.periodTimesForTimetable(provider.timetables.first).length,
        14,
      );
      expect(
        provider.periodTimesForTimetable(provider.timetables.last).length,
        14,
      );
    });

    test('仍被引用的节次时间集不能删除', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      expect(
        () => provider.deletePeriodTimeSet(provider.activePeriodTimeSet.id),
        throwsA(isA<FormatException>()),
      );
    });

    test('删除最后一个课表后进入空状态数据', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(
          initialData: AppData(
            activeTimetableId: 'only',
            timetables: [
              TimetableData(
                id: 'only',
                config: TimetableConfig(
                  name: '唯一课表',
                  startDate: DateTime(2026, 2, 23),
                  totalWeeks: 18,
                  periodTimeSetId: 'set1',
                ),
                courses: const [],
              ),
            ],
            periodTimeSets: [
              PeriodTimeSet(
                id: 'set1',
                name: '默认节次',
                periodTimes: buildPeriodTimesForCount(10),
              ),
            ],
          ),
        ),
      );
      await provider.load();
      await provider.deleteTimetable('only');

      expect(provider.activeTimetableOrNull, isNull);
      expect(provider.timetables, isEmpty);
    });

    test('节次数量可以超过默认模板长度并自动补齐', () {
      final periodTimes = buildPeriodTimesForCount(16);

      expect(periodTimes.length, 16);
      expect(periodTimes.last.index, 16);
      expect(
        periodTimes.last.endMinutes,
        greaterThan(periodTimes[11].endMinutes),
      );
    });
  });

  group('主页与编辑器', () {
    testWidgets('未加载时先显示加载态', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );

      await tester.pumpWidget(MyApp(provider: provider));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('主页显示精简标题、右上角添加课程且无 FAB', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh'), Locale('en')],
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 ${provider.selectedWeek} 周'), findsOneWidget);
      expect(find.text(provider.activeTimetable.config.name), findsOneWidget);
      expect(find.byTooltip('添加课程'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
    });

    testWidgets('新建课程时显示周次入口且节次由时间自动推导', (tester) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          CourseEditorSheet(
            periodTimes: buildDefaultPeriodTimes().take(4).toList(),
            totalWeeks: 18,
            dayOfWeek: 2,
          ),
        ),
      );

      expect(find.text('周次'), findsOneWidget);
      expect(find.text('第 1-18 周'), findsOneWidget);
      expect(find.text('关联节次'), findsOneWidget);
      expect(find.text('第 1-2 节'), findsOneWidget);
    });

    testWidgets('课程详情优先展示地点和时间卡片', (tester) async {
      final course = _buildTestAppData().timetables.first.courses.first;

      await tester.pumpWidget(
        _buildLocalizedApp(CourseDetailsSheet(course: course, onEdit: () {})),
      );

      expect(find.text('地点'), findsOneWidget);
      expect(find.text('时间'), findsOneWidget);
      expect(find.text(course.location), findsOneWidget);
      expect(find.textContaining(course.timeRange), findsOneWidget);
    });

    testWidgets('没有课表时显示新建和导入引导', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(
          initialData: AppData(
            activeTimetableId: '',
            timetables: const [],
            periodTimeSets: [
              PeriodTimeSet(
                id: 'set1',
                name: '默认节次',
                periodTimes: [
                  CoursePeriodTime(
                    index: 1,
                    startMinutes: 480,
                    endMinutes: 525,
                  ),
                ],
              ),
            ],
            privacyPolicyAcceptedVersion: currentPrivacyPolicyVersion,
          ),
        ),
      );
      await provider.load();

      await tester.pumpWidget(MyApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('当前没有课表'), findsOneWidget);
      expect(find.text('新建课表'), findsOneWidget);
      expect(find.text('导入课表'), findsOneWidget);
    });

    testWidgets('完全冲突时默认显示更长课程并显示冲突标记', (tester) async {
      final periodTimes = buildDefaultPeriodTimes().take(4).toList();
      final timetable = TimetableData(
        id: 'table1',
        config: TimetableConfig(
          name: '测试课表',
          startDate: DateTime(2026, 2, 23),
          totalWeeks: 18,
          periodTimeSetId: 'set1',
        ),
        courses: [
          CourseItem(
            id: 'long',
            name: '长课',
            teacher: '',
            location: 'A101',
            dayOfWeek: 1,
            semesterWeeks: const [1],
            periods: const [1, 2],
            startMinutes: periodTimes[0].startMinutes,
            endMinutes: periodTimes[1].endMinutes,
            timeRange: buildTimeRange(
              periodTimes[0].startMinutes,
              periodTimes[1].endMinutes,
            ),
            credit: 0,
            remarks: '',
            customFields: const {},
          ),
          CourseItem(
            id: 'short',
            name: '短课',
            teacher: '',
            location: 'B202',
            dayOfWeek: 1,
            semesterWeeks: const [1],
            periods: const [1],
            startMinutes: periodTimes[0].startMinutes,
            endMinutes: periodTimes[0].endMinutes,
            timeRange: buildTimeRange(
              periodTimes[0].startMinutes,
              periodTimes[0].endMinutes,
            ),
            credit: 0,
            remarks: '',
            customFields: const {},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: TimetableGrid(
                timetable: timetable,
                periodTimes: periodTimes,
                weekDateStart: DateTime(2026, 2, 23),
                selectedWeek: 1,
                realCurrentWeek: 1,
                localeCode: 'zh',
                preserveGaps: true,
                showPastEndedCourses: false,
                showFutureCourses: true,
                showGridLines: true,
                onCourseTap: (_) {},
                onEmptySlotTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('长课'), findsOneWidget);
      expect(find.text('短课'), findsNothing);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    });

    testWidgets('完全冲突时会读取已保存的外部显示课程偏好', (tester) async {
      final periodTimes = buildDefaultPeriodTimes().take(4).toList();
      final timetable = TimetableData(
        id: 'table1',
        config: TimetableConfig(
          name: '测试课表',
          startDate: DateTime(2026, 2, 23),
          totalWeeks: 18,
          periodTimeSetId: 'set1',
        ),
        courses: [
          CourseItem(
            id: 'a_long',
            name: '长课',
            teacher: '',
            location: 'A101',
            dayOfWeek: 1,
            semesterWeeks: const [1],
            periods: const [1, 2],
            startMinutes: periodTimes[0].startMinutes,
            endMinutes: periodTimes[1].endMinutes,
            timeRange: buildTimeRange(
              periodTimes[0].startMinutes,
              periodTimes[1].endMinutes,
            ),
            credit: 0,
            remarks: '',
            customFields: const {},
          ),
          CourseItem(
            id: 'b_short',
            name: '短课',
            teacher: '',
            location: 'B202',
            dayOfWeek: 1,
            semesterWeeks: const [1],
            periods: const [1],
            startMinutes: periodTimes[0].startMinutes,
            endMinutes: periodTimes[0].endMinutes,
            timeRange: buildTimeRange(
              periodTimes[0].startMinutes,
              periodTimes[0].endMinutes,
            ),
            credit: 0,
            remarks: '',
            customFields: const {},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 700,
              child: TimetableGrid(
                timetable: timetable,
                periodTimes: periodTimes,
                weekDateStart: DateTime(2026, 2, 23),
                selectedWeek: 1,
                realCurrentWeek: 1,
                localeCode: 'zh',
                preserveGaps: true,
                showPastEndedCourses: false,
                showFutureCourses: true,
                showGridLines: true,
                displayedCourseIdForConflict: (_) => 'b_short',
                onCourseTap: (_) {},
                onEmptySlotTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('短课'), findsOneWidget);
      expect(find.text('长课'), findsNothing);
    });
  });
}
