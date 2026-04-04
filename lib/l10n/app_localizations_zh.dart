// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Classmate';

  @override
  String weekLabel(int week) {
    return '第 $week 周';
  }

  @override
  String get addCourse => '添加课程';

  @override
  String get settings => '设置';

  @override
  String get multiTimetableSwitch => '多课表切换';

  @override
  String currentTimetableWeeks(int weeks) {
    return '当前课表 · 共 $weeks 周';
  }

  @override
  String tapToSwitchWeeks(int weeks) {
    return '点击切换 · 共 $weeks 周';
  }

  @override
  String get editTimetable => '编辑课表';

  @override
  String get createTimetable => '新建课表';

  @override
  String get jumpToWeek => '快捷跳转周数';

  @override
  String get timetable => '课表';

  @override
  String get timetableName => '课表名称';

  @override
  String get totalWeeks => '总周数';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get deleteTimetableTitle => '删除课表';

  @override
  String deleteTimetableMessage(Object name) {
    return '确认删除“$name”吗？';
  }

  @override
  String get noTimetableTitle => '当前没有课表';

  @override
  String get noTimetableMessage => '可以新建一个课表，或从 JSON 文件导入已有课表。';

  @override
  String get importTimetable => '导入课表';

  @override
  String get courseName => '课程名称';

  @override
  String get location => '上课地点';

  @override
  String get dayOfWeek => '上课日';

  @override
  String get semesterWeeks => '周次';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get linkedPeriods => '关联节次';

  @override
  String get linkedPeriodsUnmatched => '当前时间未匹配到节次，点此手动选择';

  @override
  String periodRangeLabel(int start, int end) {
    return '第 $start-$end 节';
  }

  @override
  String get teacherName => '老师姓名';

  @override
  String get credits => '学分';

  @override
  String get remarks => '备注';

  @override
  String get customFields => '自定义字段';

  @override
  String get customFieldsHint => '每行一个，格式：键:值';

  @override
  String get selectDayOfWeek => '选择上课日';

  @override
  String get selectSemesterWeeks => '选择周次';

  @override
  String get selectAll => '全选';

  @override
  String get clear => '清空';

  @override
  String get confirm => '确定';

  @override
  String get selectLinkedPeriods => '选择关联节次';

  @override
  String get addCourseTitle => '添加课程';

  @override
  String get editCourseTitle => '编辑课程';

  @override
  String get editCourseTooltip => '编辑课程';

  @override
  String get place => '地点';

  @override
  String get time => '时间';

  @override
  String get notFilled => '未填写';

  @override
  String get none => '无';

  @override
  String get conflictCourses => '冲突课程';

  @override
  String get locationNotFilled => '未填写地点';

  @override
  String get setAsDisplayed => '设为外部显示';

  @override
  String get editThisCourse => '编辑这门课';

  @override
  String get settingsTitle => '设置';

  @override
  String get noTimetableSettings => '当前没有可设置的课表';

  @override
  String get semesterStartDate => '开学日期';

  @override
  String get periodTimeSets => '节次时间集';

  @override
  String get noPeriodTimeAvailable => '暂无可用节次时间';

  @override
  String periodTimeSetSummary(Object name, int count) {
    return '$name · $count 节';
  }

  @override
  String get coursePopupDismissSetting => '允许点击空白处关闭课程弹窗';

  @override
  String get coursePopupDismissSettingHint => '关闭后也会一并禁用下拉手势关闭，避免误触。';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get dataImportExport => '导入导出数据';

  @override
  String get dataImportExportDesc => '导入整包/单课表，或导出当前课表与全部课表';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get openSourceLicensesDesc => '查看依赖与应用图标的许可信息';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get openGithubFailed => '无法打开 GitHub 仓库链接';

  @override
  String get selectPeriodTimeSet => '选择节次时间集';

  @override
  String get newItem => '新建';

  @override
  String get editPeriodTimeSet => '编辑节次时间集';

  @override
  String get importTimetableFiles => '导入课表';

  @override
  String get importTimetableFilesDesc => '支持单个或多个课表文件';

  @override
  String get shareTimetableFiles => '分享课表文件';

  @override
  String get shareTimetableFilesDesc => '先选择一个或多个课表';

  @override
  String get saveTimetableFiles => '保存课表文件';

  @override
  String get saveTimetableFilesDesc => '先选择一个或多个课表';

  @override
  String get share => '分享';

  @override
  String get selectTimetablesToExport => '选择要导出的课表';

  @override
  String get selectTimetablesToImport => '选择要导入的课表';

  @override
  String timetableCourseCount(int count) {
    return '$count 门课程';
  }

  @override
  String get importAction => '导入';

  @override
  String get importTimetableDialogTitle => '导入课表';

  @override
  String get chooseImportMethod => '请选择导入方式';

  @override
  String get importAsNewTimetable => '作为新课表导入';

  @override
  String get replaceCurrentTimetable => '覆盖当前课表';

  @override
  String savedToPath(Object path) {
    return '已保存到 $path';
  }

  @override
  String get saveCancelled => '已取消保存';

  @override
  String get fileSaveRestrictedTitle => '文件保存受限';

  @override
  String get fileSaveRestrictedRetryMessage => '当前系统未能完成文件保存。你可以重试，或改用文件分享。';

  @override
  String get retrySave => '重试保存';

  @override
  String get fileSaveRestrictedSettingsMessage => '请在系统设置中打开文件访问权限，然后返回重试导出。';

  @override
  String get openSettings => '打开设置';

  @override
  String get browserDownloadRestrictedTitle => '浏览器下载受限';

  @override
  String get browserDownloadRestrictedMessage =>
      '当前浏览器不支持直接保存到本地文件。你可以检查浏览器下载权限，或改用分享文件。';

  @override
  String get switchToShare => '改用分享';

  @override
  String get fileSaveFailedTitle => '文件保存失败';

  @override
  String get fileSaveFailedWindowsMessage =>
      '无法写入当前路径，可能是目标文件夹受系统保护、文件被占用，或当前路径不可写。';

  @override
  String get fileSaveFailedGenericMessage => '系统未能完成文件保存。你可以重试、检查系统设置，或改用文件分享。';

  @override
  String get retryLater => '稍后再试';

  @override
  String get exportSwitchedToShare => '已改用文件分享导出';

  @override
  String get saveFailedRetry => '保存失败，请稍后重试';

  @override
  String get importFailedCheckContent => '导入失败，请检查文件内容';

  @override
  String get noImportableTimetables => '导入文件中没有可用课表';

  @override
  String importedTimetablesCount(int count) {
    return '已导入 $count 个课表';
  }

  @override
  String get periodTimesTitle => '节次时间';

  @override
  String get importExport => '导入导出';

  @override
  String get importPeriodTemplate => '导入节次模板';

  @override
  String get sharePeriodTemplate => '分享节次模板';

  @override
  String get saveTemplateToFile => '保存模板到文件';

  @override
  String get deletePeriodTimeSet => '删除节次时间';

  @override
  String get periodTimeSetName => '节次时间名称';

  @override
  String get addOnePeriod => '增加一节';

  @override
  String periodNumberLabel(int index) {
    return '第 $index 节';
  }

  @override
  String get deleteThisPeriod => '删除本节';

  @override
  String durationMinutes(int minutes) {
    return '时长 $minutes 分钟';
  }

  @override
  String gapFromPrevious(int minutes) {
    return '与上一节间隔 $minutes 分钟';
  }

  @override
  String get endTimeMustBeLater => '结束时间必须晚于开始时间';

  @override
  String get periodOverlapPrevious => '当前节次与上一节时间重叠';

  @override
  String get periodTimesSaved => '已保存节次时间';

  @override
  String get deletePeriodTimeSetTitle => '删除节次时间';

  @override
  String deletePeriodTimeSetMessage(Object name) {
    return '确认删除“$name”吗？';
  }

  @override
  String get currentPeriodTimeSet => '当前节次时间';

  @override
  String importedPeriodTimesCount(int count) {
    return '已导入 $count 条节次时间';
  }

  @override
  String get periodFilePermissionTitle => '需要文件权限';

  @override
  String get androidFilePermissionMessage => 'Android 导出需要文件访问权限，请授权后继续保存。';

  @override
  String get reauthorize => '重新授权';

  @override
  String get permissionPermanentlyDeniedTitle => '权限已被永久拒绝';

  @override
  String get permissionSettingsExportMessage => '请在系统设置中打开文件访问权限，然后再回来重试导出。';
}
