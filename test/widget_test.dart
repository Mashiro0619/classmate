import 'dart:convert';
import 'dart:io';

import 'package:classmate/config/app_config.dart';
import 'package:classmate/data/timetable_storage.dart';
import 'package:classmate/l10n/app_localizations.dart';
import 'package:classmate/main.dart' hide main;
import 'package:classmate/models/timetable_models.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:classmate/screens/home_screen.dart';
import 'package:classmate/screens/settings_page.dart';
import 'package:classmate/screens/theme_settings_page.dart';
import 'package:classmate/services/update_service.dart';
import 'package:classmate/widgets/course_details_sheet.dart';
import 'package:classmate/widgets/course_editor_sheet.dart';
import 'package:classmate/widgets/timetable_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

class FakeSuccessUpdateService extends UpdateService {
  const FakeSuccessUpdateService(this.result);

  final UpdateCheckResult result;

  @override
  Future<UpdateCheckResult> checkForUpdates({Locale? preferredLocale}) async {
    return result;
  }
}

class FakeThrowingUpdateService extends UpdateService {
  const FakeThrowingUpdateService(this.error);

  final Object error;

  @override
  Future<UpdateCheckResult> checkForUpdates({Locale? preferredLocale}) async {
    throw error;
  }
}

Widget _buildLocalizedApp(Widget child, {Locale locale = const Locale('zh')}) {
  return MaterialApp(
    locale: locale,
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

Future<BuildContext> _pumpUpdateHarness(
  WidgetTester tester, {
  required TimetableProvider provider,
  Locale locale = const Locale('zh'),
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    ChangeNotifierProvider<TimetableProvider>.value(
      value: provider,
      child: _buildLocalizedApp(
        Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
        locale: locale,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return context;
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
        systemLocaleCodeResolver: () => 'zh',
      );
      await firstProvider.load();

      expect(await file.exists(), isTrue);
      expect(firstProvider.activeTimetable.config.name, '空课表');

      final secondProvider = TimetableProvider(
        storage: TestTimetableStorage(file),
        systemLocaleCodeResolver: () => 'zh',
      );
      await secondProvider.load();

      expect(secondProvider.timetables, isEmpty);
      expect(secondProvider.activeTimetable.config.name, '空课表');
    });

    test('首次启动语言检测仅对繁体中文映射为中文', () {
      expect(resolveFirstLaunchLocaleCode(const Locale('zh', 'TW')), 'zh');
      expect(resolveFirstLaunchLocaleCode(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')), 'zh');
      expect(resolveFirstLaunchLocaleCode(const Locale('zh', 'HK')), 'zh');
    });

    test('首次启动语言检测对其他语言一律映射为英文', () {
      expect(resolveFirstLaunchLocaleCode(null), 'en');
      expect(resolveFirstLaunchLocaleCode(const Locale('en')), 'en');
      expect(resolveFirstLaunchLocaleCode(const Locale('ja')), 'en');
      expect(resolveFirstLaunchLocaleCode(const Locale('zh', 'CN')), 'en');
      expect(resolveFirstLaunchLocaleCode(const Locale('zh')), 'en');
    });

    test('中文系语言默认使用配置的更新接口', () {
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('zh')), isTrue);
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('zh', 'CN')), isTrue);
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('zh', 'TW')), isTrue);
    });

    test('非中文系语言默认使用 GitHub 更新源', () {
      expect(prefersConfiguredUpdateSourceForLocale(null), isFalse);
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('en')), isFalse);
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('ja')), isFalse);
      expect(prefersConfiguredUpdateSourceForLocale(const Locale('fr')), isFalse);
    });

    test('中文系主源格式错误时会回退到 GitHub', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Classmate',
        packageName: 'com.mashiro.classmate',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final service = UpdateService(
        client: MockClient((request) async {
          if (request.url.toString() == AppConfig.updateVersionUrl) {
            return http.Response('{"version":""}', 200);
          }
          if (request.url.toString().contains('/releases/latest')) {
            return http.Response(
              jsonEncode({
                'tag_name': 'v1.2.0',
                'html_url': 'https://github.com/Mashiro0619/classmate/releases/tag/v1.2.0',
                'body': 'notes',
              }),
              200,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final result = await service.checkForUpdates(
        preferredLocale: const Locale('zh'),
      );

      expect(result.remoteVersion, '1.2.0');
      expect(result.hasUpdate, isTrue);
    });

    test('非中文系主源格式错误时会回退到配置接口', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Classmate',
        packageName: 'com.mashiro.classmate',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final service = UpdateService(
        client: MockClient((request) async {
          if (request.url.toString().contains('/releases/latest')) {
            return http.Response('{"tag_name":""}', 200);
          }
          if (request.url.toString() == AppConfig.updateVersionUrl) {
            return http.Response(
              jsonEncode({'version': '1.3.0', 'updateContent': 'notes'}),
              200,
            );
          }
          return http.Response('not found', 404);
        }),
      );

      final result = await service.checkForUpdates(
        preferredLocale: const Locale('en'),
      );

      expect(result.remoteVersion, '1.3.0');
      expect(result.hasUpdate, isTrue);
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

    test('当天课程结束后会命中第二天第一节课', () {
      final periodTimes = buildDefaultPeriodTimes();
      final timetable = TimetableData(
        id: 'table_next_day',
        config: TimetableConfig(
          name: '测试课表',
          startDate: DateTime(2026, 2, 23),
          totalWeeks: 18,
          periodTimeSetId: 'set1',
        ),
        courses: [
          CourseItem(
            id: 'today_course',
            name: '今天的课',
            teacher: '',
            location: '',
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
            id: 'tomorrow_first',
            name: '明天第一节',
            teacher: '',
            location: '',
            dayOfWeek: 2,
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

      final target = currentOrNextCourseTargetFor(
        timetable: timetable,
        selectedWeek: 1,
        realCurrentWeek: 1,
        now: DateTime(2026, 2, 23, 22, 30),
      );

      expect(target?.week, 1);
      expect(target?.weekday, 2);
      expect(target?.courseId, 'tomorrow_first');
    });

    test('周日课程结束后会命中下周一第一节课', () {
      final periodTimes = buildDefaultPeriodTimes();
      final timetable = TimetableData(
        id: 'table_cross_week',
        config: TimetableConfig(
          name: '测试课表',
          startDate: DateTime(2026, 2, 23),
          totalWeeks: 18,
          periodTimeSetId: 'set1',
        ),
        courses: [
          CourseItem(
            id: 'next_week_monday',
            name: '下周一第一节',
            teacher: '',
            location: '',
            dayOfWeek: 1,
            semesterWeeks: const [2],
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

      final target = currentOrNextCourseTargetFor(
        timetable: timetable,
        selectedWeek: 2,
        realCurrentWeek: 1,
        now: DateTime(2026, 3, 1, 22, 30),
      );

      expect(target?.week, 2);
      expect(target?.weekday, 1);
      expect(target?.courseId, 'next_week_monday');
    });

    test('copyWith 可以显式清空更新状态字段', () {
      final data = _buildTestAppData().copyWith(
        ignoredUpdateVersion: '1.6.10',
        availableUpdateVersion: '1.6.10',
      );
      final cleared = data.copyWith(
        ignoredUpdateVersion: null,
        availableUpdateVersion: null,
      );

      expect(cleared.ignoredUpdateVersion, isNull);
      expect(cleared.availableUpdateVersion, isNull);
    });

    test('描边设置字段可以正确编码解码并兼容旧数据默认值', () {
      final customized = _buildTestAppData().copyWith(
        liveCourseOutlineEnabled: false,
        liveCourseOutlineFollowTheme: false,
        liveCourseOutlineCustomColorInitialized: true,
        liveCourseOutlineColorValue: 0xFF123456,
        liveCourseOutlineWidth: 3.5,
      );
      final decodedCustomized = AppData.decode(customized.encode());

      expect(decodedCustomized.liveCourseOutlineEnabled, isFalse);
      expect(decodedCustomized.liveCourseOutlineFollowTheme, isFalse);
      expect(decodedCustomized.liveCourseOutlineCustomColorInitialized, isTrue);
      expect(decodedCustomized.liveCourseOutlineColorValue, 0xFF123456);
      expect(decodedCustomized.liveCourseOutlineWidth, 3.5);

      final legacy = AppData.decode(
        jsonEncode({
          'activeTimetableId': '',
          'timetables': const [],
          'periodTimeSets': [
            {
              'id': 'set1',
              'name': '默认节次',
              'periodTimes': [
                {
                  'index': 1,
                  'startMinutes': 480,
                  'endMinutes': 525,
                },
              ],
            },
          ],
        }),
      );

      expect(legacy.liveCourseOutlineEnabled, isTrue);
      expect(legacy.liveCourseOutlineFollowTheme, isTrue);
      expect(legacy.liveCourseOutlineCustomColorInitialized, isFalse);
      expect(legacy.liveCourseOutlineWidth, defaultLiveCourseOutlineWidth);
    });

    test('首次加载无本地数据时会按系统语言初始化英文', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(),
        systemLocaleCodeResolver: () => 'en',
      );
      await provider.load();

      expect(provider.localeCode, 'en');
      expect(provider.activePeriodTimeSet.name, 'Default periods');
    });

    test('已有本地语言设置时不会被系统语言覆盖', () async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(
          initialData: _buildTestAppData().copyWith(localeCode: 'zh'),
        ),
        systemLocaleCodeResolver: () => 'en',
      );
      await provider.load();

      expect(provider.localeCode, 'zh');
    });

    test('跟随主题色的描边派生色会比旧实现更浅但仍深于原色', () {
      const seedColor = Color(0xFF6750A4);
      final derivedColor = deriveLiveCourseOutlineColorFromSeed(seedColor);
      final oldDerivedColor = HSLColor.fromColor(seedColor)
          .withLightness(
            (HSLColor.fromColor(seedColor).lightness - 0.16)
                .clamp(0.18, 0.72)
                .toDouble(),
          )
          .withSaturation(
            (HSLColor.fromColor(seedColor).saturation + 0.08)
                .clamp(0.12, 1.0)
                .toDouble(),
          )
          .toColor();
      final derivedHsl = HSLColor.fromColor(derivedColor);
      final seedHsl = HSLColor.fromColor(seedColor);
      final oldDerivedHsl = HSLColor.fromColor(oldDerivedColor);

      expect(derivedHsl.lightness, lessThan(seedHsl.lightness));
      expect(derivedHsl.lightness, greaterThan(oldDerivedHsl.lightness));
    });
  });

  group('课表显示设置', () {
    testWidgets('关闭跟随主题色时会初始化自定义描边颜色', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('zh'), Locale('en')],
            home: ThemeSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('当前/下一节课程描边'),
        200,
      );
      await tester.tap(find.text('当前/下一节课程描边'));
      await tester.pumpAndSettle();

      expect(provider.liveCourseOutlineFollowTheme, isTrue);
      expect(provider.liveCourseOutlineCustomColorInitialized, isFalse);

      await tester.tap(
        find.widgetWithText(SwitchListTile, '跟随主题色'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用设置'));
      await tester.pumpAndSettle();

      expect(provider.liveCourseOutlineFollowTheme, isFalse);
      expect(provider.liveCourseOutlineCustomColorInitialized, isTrue);
      expect(
        provider.liveCourseOutlineColorValue,
        deriveLiveCourseOutlineColorFromSeed(
          Color(provider.themeSeedColorValue),
        ).toARGB32(),
      );
    });

    testWidgets('关闭课程描边后 provider 会保存设置', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('zh'), Locale('en')],
            home: ThemeSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('当前/下一节课程描边'),
        200,
      );
      await tester.tap(find.text('当前/下一节课程描边'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, '开启课程描边'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用设置'));
      await tester.pumpAndSettle();

      expect(provider.liveCourseOutlineEnabled, isFalse);
    });

    testWidgets('描边宽度显示会带单位', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('zh'), Locale('en')],
            home: ThemeSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('当前/下一节课程描边'),
        200,
      );
      expect(find.text('2.5 px'), findsOneWidget);

      await tester.tap(find.text('当前/下一节课程描边'));
      await tester.pumpAndSettle();

      expect(find.text('2.5 px'), findsWidgets);
    });

    testWidgets('调整描边宽度后 provider 会保存设置', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('zh'), Locale('en')],
            home: ThemeSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('当前/下一节课程描边'),
        200,
      );
      await tester.tap(find.text('当前/下一节课程描边'));
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(240, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用设置'));
      await tester.pumpAndSettle();

      expect(provider.liveCourseOutlineWidth, greaterThan(defaultLiveCourseOutlineWidth));
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

    testWidgets('首次未同意隐私政策时显示弹窗而不是整页', (tester) async {
      final initialData = _buildTestAppData();
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(
          initialData: AppData(
            activeTimetableId: initialData.activeTimetableId,
            timetables: initialData.timetables,
            periodTimeSets: initialData.periodTimeSets,
            conflictDisplayCourseIds: initialData.conflictDisplayCourseIds,
            closeCoursePopupOnOutsideTap:
                initialData.closeCoursePopupOnOutsideTap,
            preserveTimetableGaps: initialData.preserveTimetableGaps,
            showPastEndedCourses: initialData.showPastEndedCourses,
            showFutureCourses: initialData.showFutureCourses,
            showTimetableGridLines: initialData.showTimetableGridLines,
            localeCode: initialData.localeCode,
            themeMode: initialData.themeMode,
            themeSeedColorValue: initialData.themeSeedColorValue,
            liveCourseOutlineColorValue: initialData.liveCourseOutlineColorValue,
            liveCourseOutlineEnabled: initialData.liveCourseOutlineEnabled,
            liveCourseOutlineFollowTheme:
                initialData.liveCourseOutlineFollowTheme,
            liveCourseOutlineCustomColorInitialized:
                initialData.liveCourseOutlineCustomColorInitialized,
            liveCourseOutlineWidth: initialData.liveCourseOutlineWidth,
          ),
        ),
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

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('使用前请先同意隐私政策'), findsOneWidget);
      expect(find.text('测试课表A'), findsOneWidget);
      expect(find.text('查看完整隐私政策'), findsOneWidget);
      expect(find.text('同意并继续'), findsOneWidget);

      await tester.tap(find.text('同意并继续'));
      await tester.pumpAndSettle();

      expect(provider.hasAcceptedCurrentPrivacyPolicy, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('第 ${provider.selectedWeek} 周'), findsOneWidget);
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
      final appData = _buildTestAppData();
      final course = appData.timetables.first.courses.first;
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: appData),
      );
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: _buildLocalizedApp(
            CourseDetailsSheet(
              courseId: course.id,
              weekday: course.dayOfWeek,
              conflictKey: null,
              isFullConflict: false,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.text('地点'), findsOneWidget);
      expect(find.text('时间'), findsOneWidget);
      expect(find.text(course.location), findsOneWidget);
      expect(find.textContaining(course.timeRange), findsOneWidget);
    });

    testWidgets('手动检测更新时的更新弹窗包含官网 Google Play GitHub 和网盘按钮', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();
      final context = await _pumpUpdateHarness(tester, provider: provider);

      final future = AppUpdateCoordinator.checkForUpdates(
        context,
        provider: provider,
        source: UpdateCheckSource.manual,
        updateService: const FakeSuccessUpdateService(
          UpdateCheckResult(
            localVersion: '1.0.0',
            remoteVersion: '1.1.0',
            releaseUrl: 'https://github.com/Mashiro0619/classmate/releases/latest',
            officialWebsiteUrl: 'https://mashiro.tech/classmate',
            updateContent: '更新说明',
            hasUpdate: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('官网'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('网盘'), findsOneWidget);
      expect(find.text('忽略此版本'), findsNothing);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('检测更新失败时会显示错误弹窗并提供官网 Google Play GitHub 和网盘按钮', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();
      final context = await _pumpUpdateHarness(tester, provider: provider);

      final future = AppUpdateCoordinator.checkForUpdates(
        context,
        provider: provider,
        source: UpdateCheckSource.manual,
        updateService: FakeThrowingUpdateService(Exception('boom')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('检测更新失败'), findsOneWidget);
      expect(find.text('官网'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('网盘'), findsOneWidget);
      expect(find.text('忽略此版本'), findsNothing);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await future;
    });

    testWidgets('启动时检测更新失败的错误弹窗包含忽略此版本', (tester) async {
      final provider = TimetableProvider(
        storage: MemoryTimetableStorage(initialData: _buildTestAppData()),
      );
      await provider.load();
      final context = await _pumpUpdateHarness(tester, provider: provider);

      final future = AppUpdateCoordinator.checkForUpdates(
        context,
        provider: provider,
        source: UpdateCheckSource.startup,
        updateService: FakeThrowingUpdateService(Exception('boom')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('检测更新失败'), findsOneWidget);
      expect(find.text('忽略此版本'), findsOneWidget);
      expect(find.text('官网'), findsOneWidget);
      expect(find.text('Google Play'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('网盘'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await future;
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
                liveCourseOutlineEnabled: true,
                onCourseTap: (_) {},
                onEmptySlotTap: (_) {},
                liveCourseOutlineColorValue: defaultLiveCourseOutlineColorValue,
                liveCourseOutlineWidth: defaultLiveCourseOutlineWidth,
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
                liveCourseOutlineEnabled: true,
                onCourseTap: (_) {},
                onEmptySlotTap: (_) {},
                liveCourseOutlineColorValue: defaultLiveCourseOutlineColorValue,
                liveCourseOutlineWidth: defaultLiveCourseOutlineWidth,
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
