import 'package:shared_preferences/shared_preferences.dart';

import '../models/timetable_models.dart';
import 'timetable_storage.dart';

TimetableStorage createTimetableStorage() => _BrowserTimetableStorage();

/// Web 端改用浏览器可用的键值存储，但仍保存同一份 JSON 字符串。
class _BrowserTimetableStorage implements TimetableStorage {
  static const _storageKey = 'classmate_app_data';

  @override
  Future<AppData?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final content = preferences.getString(_storageKey);
    if (content == null || content.trim().isEmpty) {
      return null;
    }
    return AppData.decode(content);
  }

  @override
  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, data.encode());
  }

  @override
  Future<String?> filePath() async =>
      'browser://local-storage/classmate_app_data';
}
