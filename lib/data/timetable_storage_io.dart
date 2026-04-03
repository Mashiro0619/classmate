import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/timetable_models.dart';
import 'timetable_storage.dart';

TimetableStorage createTimetableStorage() => _IoTimetableStorage();

/// 桌面与移动端继续使用真实 JSON 文件，便于备份和调试。
class _IoTimetableStorage implements TimetableStorage {
  static const _fileName = 'classmate_data.json';

  @override
  Future<AppData?> load() async {
    final file = await _resolveFile();
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
  Future<void> save(AppData data) async {
    final file = await _resolveFile();
    await file.writeAsString(data.encode());
  }

  @override
  Future<String> filePath() async {
    final file = await _resolveFile();
    return file.path;
  }

  Future<File> _resolveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = path.join(directory.path, _fileName);
    return File(filePath);
  }
}
