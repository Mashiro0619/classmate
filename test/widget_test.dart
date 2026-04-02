import 'dart:io';

import 'package:classmate/data/timetable_storage.dart';
import 'package:classmate/main.dart';
import 'package:classmate/models/timetable_models.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试专用 JSON 存储实现，避免污染真实用户目录。
class TestTimetableStorage extends TimetableStorage {
  TestTimetableStorage(this.file);

  final File file;

  @override
  Future<void> save(data) async {
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
  Future<String> filePath() async => file.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows timetable home screen', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tempDir = await Directory.systemTemp.createTemp('classmate_test');
    final file = File('${tempDir.path}/classmate_data.json');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final provider = TimetableProvider(storage: TestTimetableStorage(file));
    await provider.load();

    await tester.pumpWidget(MyApp(provider: provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('添加课程'), findsWidgets);
    expect(find.textContaining('第 '), findsWidgets);
    expect(find.text('2026 春季学期'), findsOneWidget);
  });
}
