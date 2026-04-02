import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/timetable_models.dart';

/// 负责把课表数据落到真实 JSON 文件中，方便后续备份、导入和调试。
class TimetableStorage {
  static const _fileName = 'classmate_data.json';

  /// 读取本地 JSON 文件；若文件不存在则返回 null。
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

  /// 覆写保存整个应用数据快照。
  Future<void> save(AppData data) async {
    final file = await _resolveFile();
    await file.writeAsString(data.encode());
  }

  /// 暴露文件路径，便于后续做导出入口或调试展示。
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
