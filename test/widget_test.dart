import 'dart:io';

import 'package:classmate/data/timetable_storage.dart';
import 'package:classmate/main.dart' hide main;
import 'package:classmate/models/timetable_models.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:classmate/screens/home_screen.dart';
import 'package:classmate/widgets/course_editor_sheet.dart';
import 'package:flutter/material.dart';
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
  MemoryTimetableStorage({AppData? initialData}) : _content = initialData?.encode();

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

void main() {
  group('课表 JSON 存储', () {
    test('示例数据可以正确编码和解码', () {
      final data = buildSampleAppData();
      final encoded = data.encode();
      final decoded = AppData.decode(encoded);

      expect(decoded.activeTimetableId, data.activeTimetableId);
      expect(decoded.timetables.length, data.timetables.length);
      expect(decoded.timetables.first.config.name, '2026 春季学期');
    });

    test('旧 weekday 字段可以兼容解码并统一写回 weekdays', () {
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

      expect(course.weekdays, [3]);
      expect(course.toJson()['weekdays'], [3]);
      expect(course.toJson().containsKey('weekday'), isFalse);
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

      final firstProvider = TimetableProvider(storage: TestTimetableStorage(file));
      await firstProvider.load();

      expect(await file.exists(), isTrue);
      expect(firstProvider.activeTimetable.config.name, '2026 春季学期');

      final secondProvider = TimetableProvider(storage: TestTimetableStorage(file));
      await secondProvider.load();

      expect(secondProvider.timetables.isNotEmpty, isTrue);
      expect(secondProvider.activeTimetable.id, firstProvider.activeTimetable.id);
    });
  });

  group('主页与编辑器', () {
    testWidgets('未加载时先显示加载态', (tester) async {
      final provider = TimetableProvider(storage: MemoryTimetableStorage(initialData: buildSampleAppData()));

      await tester.pumpWidget(MyApp(provider: provider));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('主页显示精简标题、右上角添加课程且无 FAB', (tester) async {
      final provider = TimetableProvider(storage: MemoryTimetableStorage(initialData: buildSampleAppData()));
      await provider.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 ${provider.selectedWeek} 周'), findsOneWidget);
      expect(find.text(provider.activeTimetable.config.name), findsOneWidget);
      expect(find.byTooltip('添加课程'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.horizontal,
        ),
        findsNothing,
      );
    });

    testWidgets('新建课程时默认全选星期', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseEditorSheet(
              periodTimes: buildDefaultPeriodTimes().take(4).toList(),
              weekday: 2,
            ),
          ),
        ),
      );

      final mondayChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, '星期1'));
      final sundayChip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, '星期7'));

      expect(mondayChip.selected, isTrue);
      expect(sundayChip.selected, isTrue);
    });
  });
}
