class AppConfig {
  const AppConfig._();

  static const schoolImportApiBaseUrl = String.fromEnvironment(
    'SCHOOL_IMPORT_API_BASE_URL',
    defaultValue: '',
    // 你的api
  );

  static bool get hasSchoolImportApiBaseUrl =>
      schoolImportApiBaseUrl.trim().isNotEmpty;
}
