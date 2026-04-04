import '../models/timetable_models.dart';
import 'timetable_storage_stub.dart'
    if (dart.library.io) 'timetable_storage_io.dart';

/// 统一的课表存储接口：不同平台各自决定底层实现，但都保存同一份 JSON 数据。
abstract class TimetableStorage {
  factory TimetableStorage() => createTimetableStorage();

  /// 读取应用数据；若本地还没有保存内容则返回 null。
  Future<AppData?> load();

  /// 覆写保存整个应用数据快照。
  Future<void> save(AppData data);

  /// 返回调试用的数据位置；Web 端没有真实文件时可返回虚拟路径。
  Future<String?> filePath();
}
