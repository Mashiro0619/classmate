import '../models/timetable_models.dart';
import 'timetable_storage_stub.dart'
    if (dart.library.io) 'timetable_storage_io.dart';

/// 这里只管整份 AppData 的读写，至于落文件还是浏览器存储，让平台层自己决定。
abstract class TimetableStorage {
  factory TimetableStorage() => createTimetableStorage();

  /// 首次启动还没数据时允许返回 null，这样上层可以走默认初始化流程。
  Future<AppData?> load();

  /// 统一按整份快照写回，省得在不同平台维护细碎的增量更新逻辑。
  Future<void> save(AppData data);

  /// 主要给设置页和排查问题时用；Web 没真实路径的话给个虚拟地址就行。
  Future<String?> filePath();
}
