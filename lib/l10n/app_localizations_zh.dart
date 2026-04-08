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
  String get preserveTimetableGaps => '保留课表空白时间';

  @override
  String get preserveTimetableGapsHint => '关闭后会折叠午休、下课等非上课时间，让后续课程向上拼接。';

  @override
  String get showPastEndedCourses => '显示已结束课程';

  @override
  String get showPastEndedCoursesHint => '显示按真实当前周已结束的课程，并用更浅的灰色区分。';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => '主题';

  @override
  String get themeFollowSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '暗黑';

  @override
  String get themeColor => '主题色';

  @override
  String get themeCustomColor => '自定义颜色';

  @override
  String get themeApplyCustomColor => '应用颜色';

  @override
  String get dataImportExport => '导入导出数据';

  @override
  String get dataImportExportDesc => '导入整包/单课表，或导出当前课表与全部课表';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get openSourceLicensesDesc => '查看 Flutter 依赖与应用内置图标资源的许可信息';

  @override
  String get checkForUpdates => '检测更新';

  @override
  String get checkForUpdatesDesc => 'GitHub / 官网';

  @override
  String alreadyLatestVersion(Object version) {
    return '当前已是最新版本（$version）';
  }

  @override
  String get currentVersionLabel => '当前版本';

  @override
  String get latestVersionLabel => '最新版本';

  @override
  String get updateContentLabel => '更新内容';

  @override
  String get officialWebsite => '官网';

  @override
  String get ignoreThisVersion => '忽略此版本';

  @override
  String get openUpdatesFailed => '无法打开更新链接';

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
  String get browserDownloadRestrictedMessage => '当前浏览器不支持直接保存到本地文件。你可以检查浏览器下载权限，或改用分享文件。';

  @override
  String get switchToShare => '改用分享';

  @override
  String get fileSaveFailedTitle => '文件保存失败';

  @override
  String get fileSaveFailedWindowsMessage => '无法写入当前路径，可能是目标文件夹受系统保护、文件被占用，或当前路径不可写。';

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

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get privacyPolicyEntryDesc => '了解应用如何处理本地存储、学校站点配置、文件导入导出、网页解析和外部链接。';

  @override
  String privacyPolicyAcceptedVersionLabel(Object version) {
    return '已同意版本：$version';
  }

  @override
  String get privacyPolicyIntro => 'Classmate 是一个以本地优先为主的应用。课表、课表设置、节次时间集和学校站点配置默认保存在你的设备或浏览器本地。只有在你主动发起对应操作时，应用才会读取本地文件、提交网页内容用于解析、打开外部链接或调用系统分享。';

  @override
  String get privacyPolicyLocalStorageTitle => '本地存储';

  @override
  String get privacyPolicyLocalStorageBody => '在 Android、iOS、Windows、macOS 和 Linux 等平台，课表数据和相关设置会保存在应用文档目录中的本地文件 classmate_data.json，可编辑的学校站点配置会单独保存在 classmate_school_sites.json。在 Web 端，同类数据会保存在浏览器本地存储中。应用不会自动把这些本地数据上传到开发者控制的服务器。';

  @override
  String get privacyPolicyImportExportTitle => '导入与导出';

  @override
  String get privacyPolicyImportExportBody => '只有在你主动选择文件或主动执行导出时，应用才会读取或写出 JSON 课表文件、学校站点 JSON 文件和节次模板文件。这些文件的导入导出本身属于本地操作；只有当你进一步选择网页解析时，相关页面内容才会被发送到你配置的解析接口。';

  @override
  String get privacyPolicySharingTitle => '分享功能';

  @override
  String get privacyPolicySharingBody => '当你主动使用分享功能时，应用会把你选中的导出文件交给系统分享面板或目标应用。后续如何处理该文件，由你选择的目标应用或服务自行决定。';

  @override
  String get privacyPolicyExternalLinksTitle => '外部链接';

  @override
  String get privacyPolicyExternalLinksBody => '当你主动打开 GitHub 仓库等外部链接时，应用会调用系统浏览器或其他外部应用。离开应用后的数据处理将受对应第三方的政策约束。';

  @override
  String get privacyPolicyNoCollectionTitle => '默认不收集的内容';

  @override
  String get privacyPolicyNoCollectionBody => '应用不要求你注册 Classmate 账号，也不会默认启用分析统计、广告标识符或云端备份。应用本身也没有专门采集学校账号密码的输入字段；如果你在应用内打开的学校网页中登录，该交互发生在你访问的学校页面内。';

  @override
  String get privacyPolicyFutureFeatureTitle => '网页解析';

  @override
  String get privacyPolicyFutureFeatureBody => '当你使用学校网页导入或粘贴 HTML 进行解析时，应用会先在本地压缩内容，再把你提交的页面内容、可选的页面标题与 URL，以及当前应用语言发送到你配置的解析接口。该接口可能会继续把请求转发给部署者配置的 AI 服务。当前部署的后端会限制单次提交内容不得大于 300KB，使用其配置的请求超时时间，并按 IP 每天最多解析 5 次。在课表正式保存前，应用会先展示解析结果，并允许你手动修改课表名称和开学日期。';

  @override
  String get privacyPolicyUpdatesTitle => '政策更新';

  @override
  String privacyPolicyUpdatesBody(Object version) {
    return '当前隐私政策版本为 $version。如果后续版本调整了数据处理方式，应用可能会要求你重新阅读并同意更新后的隐私政策。';
  }

  @override
  String get privacyGateTitle => '使用前请先同意隐私政策';

  @override
  String get privacyGateSummaryStorage => '课表、节次时间集和学校站点配置默认保存在本地，不会自动上传到开发者服务器。';

  @override
  String get privacyGateSummaryImportExport => '导入、导出和分享仅在你主动操作时触发；网页解析只会发送你主动提交的压缩后内容，并在保存前让你预览解析结果。';

  @override
  String get privacyGateSummaryExternal => '打开 GitHub 等外部链接会交给系统浏览器或其他应用处理。';

  @override
  String get privacyGateSummaryUpdates => '如果后续版本调整了数据处理方式，应用可能会要求你重新查看更新后的隐私政策。';

  @override
  String get schoolWebImportEntry => '从学校网页导入';

  @override
  String get schoolWebImportEntryDesc => '在应用内打开学校网站，进入课表页后导入当前页面。';

  @override
  String get schoolSitesManageEntry => '学校站点管理';

  @override
  String get schoolSitesManageEntryDesc => '新增、编辑、删除学校登录地址，并支持 JSON 导入导出。';

  @override
  String get schoolSitesPageTitle => '学校站点管理';

  @override
  String get schoolSitesImportJson => '导入学校 JSON';

  @override
  String get schoolSitesShareJson => '分享学校 JSON';

  @override
  String get schoolSitesSaveJson => '保存学校 JSON';

  @override
  String get schoolSitesSaved => '学校站点已保存';

  @override
  String get schoolSitesImported => '学校站点已导入';

  @override
  String get schoolSitesEmpty => '当前还没有学校站点配置。';

  @override
  String get schoolSitesNameLabel => '学校名称';

  @override
  String get schoolSitesLoginUrlLabel => '登录页链接';

  @override
  String get schoolSitesAdd => '新增学校';

  @override
  String get schoolSitesEdit => '编辑学校';

  @override
  String get schoolSitesDeleteTitle => '删除学校';

  @override
  String schoolSitesDeleteMessage(Object name) {
    return '确认删除“$name”吗？';
  }

  @override
  String get schoolSitesFormInvalid => '请完整填写学校名称和登录页链接。';

  @override
  String get schoolSitesJsonFileName => 'classmate_school_sites.json';

  @override
  String get schoolHtmlImportEntry => '粘贴课程表网页 HTML 导入';

  @override
  String get schoolHtmlImportEntryDesc => '手动粘贴课程表网页源码，适用于 Windows 和 Web 端。';

  @override
  String get schoolHtmlImportPageTitle => 'HTML 导入课表';

  @override
  String get schoolHtmlImportUrlLabel => '来源 URL（可选）';

  @override
  String get schoolHtmlImportTitleLabel => '页面标题（可选）';

  @override
  String get schoolHtmlImportHtmlLabel => '网页 HTML';

  @override
  String get schoolHtmlImportHtmlHint => '请粘贴完整课程表页面 HTML。';

  @override
  String get schoolHtmlImportCompress => '压缩内容';

  @override
  String get schoolHtmlImportCompressed => '内容已压缩';

  @override
  String get schoolHtmlImportCompressFirst => '请先压缩内容。';

  @override
  String get schoolHtmlImportSubmit => '解析并导入';

  @override
  String get schoolHtmlImportEmpty => '请先粘贴网页 HTML。';

  @override
  String get schoolHtmlImportReturnToWebPage => '返回网页';

  @override
  String get schoolWebImportPageTitle => '学校网页导入';

  @override
  String get schoolWebImportPreview => '导入预览';

  @override
  String schoolWebImportCourseCount(int count) {
    return '$count 门课程';
  }

  @override
  String schoolWebImportPeriodCount(int count) {
    return '$count 节';
  }

  @override
  String get schoolWebImportPageTitleLabel => '页面标题';

  @override
  String get schoolWebImportParserUsed => '解析器';

  @override
  String get schoolWebImportWarnings => '导入提示';

  @override
  String get schoolWebImportOpenPageHint => '请在应用内登录学校网站，并手动切换到课表页。';

  @override
  String get schoolWebImportConfigMissing => '尚未配置网页导入后端接口地址。';

  @override
  String get schoolWebImportUnsupportedPlatform => '当前平台暂不支持内嵌网页登录，请在支持 WebView 的平台上使用。';

  @override
  String get schoolWebImportSelectSchool => '选择学校';

  @override
  String get schoolWebImportNoSchools => '当前没有可用学校配置，请先检查 school_sites.json。';

  @override
  String get schoolWebImportSchoolLoadFailed => '学校配置加载失败，请检查 JSON 文件格式。';

  @override
  String get schoolWebImportImportCurrentPage => '导入当前页';

  @override
  String get schoolWebImportGoBack => '上一页';

  @override
  String get schoolWebImportLoadingPage => '页面加载中…';

  @override
  String get schoolWebImportParsing => '正在解析当前页面…';

  @override
  String get schoolWebImportEmptyPage => '当前页面内容为空，暂时无法导入。';

  @override
  String get schoolWebImportSuccess => '网页课表已导入';

  @override
  String get privacyViewFullPolicy => '查看完整隐私政策';

  @override
  String get privacyAgreeAndContinue => '同意并继续';

  @override
  String get privacyDecline => '不同意';

  @override
  String get privacyDeclineWebHint => '当前浏览器环境无法由应用主动关闭页面。若你不同意，请直接关闭此标签页或窗口。';
}
