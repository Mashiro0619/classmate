import 'dart:io';

import 'package:classmate/data/timetable_storage.dart';
import 'package:classmate/models/timetable_models.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试专用 JSON 存储实现，避免污染真实用户目录。
class TestTimetableStorage extends TimetableStorage {
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
  Future<String> filePath() async => file.path;
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
}
