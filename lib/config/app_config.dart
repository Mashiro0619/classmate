class AppConfig {
  const AppConfig._();

  static const schoolImportApiBaseUrl = String.fromEnvironment(
    'SCHOOL_IMPORT_API_BASE_URL',
    defaultValue: '',
    // 你的ai api
  );

  static const updateVersionUrl = String.fromEnvironment(
    'CLASSMATE_UPDATE_VERSION_URL',
    defaultValue: '',
  );
/* 你的更新接口，内容格式示例 {
  "version": "v1.0.0",
  "updateContent": "这里是更新公告"
}
*/
  static const officialWebsiteUrl = 'https://mashiro.tech/classmate';

  static bool get hasSchoolImportApiBaseUrl =>
      schoolImportApiBaseUrl.trim().isNotEmpty;

  static bool get hasUpdateVersionUrl => updateVersionUrl.trim().isNotEmpty;
}
