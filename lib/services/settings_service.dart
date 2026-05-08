import '../l10n/app_locale.dart';
import '../models/timetable_models.dart';

class SettingsService {
  const SettingsService();

  AppData updateCloseCoursePopupOnOutsideTap(AppData data, bool value) {
    if (data.closeCoursePopupOnOutsideTap == value) return data;
    return data.copyWith(closeCoursePopupOnOutsideTap: value);
  }

  AppData updatePreserveTimetableGaps(AppData data, bool value) {
    if (data.preserveTimetableGaps == value) return data;
    return data.copyWith(preserveTimetableGaps: value);
  }

  AppData updateShowPastEndedCourses(AppData data, bool value) {
    if (data.showPastEndedCourses == value) return data;
    return data.copyWith(showPastEndedCourses: value);
  }

  AppData updateShowFutureCourses(AppData data, bool value) {
    if (data.showFutureCourses == value) return data;
    return data.copyWith(showFutureCourses: value);
  }

  AppData updateShowTimetableGridLines(AppData data, bool value) {
    if (data.showTimetableGridLines == value) return data;
    return data.copyWith(showTimetableGridLines: value);
  }

  AppData updateLocaleCode(AppData data, String localeCode) {
    if (data.localeCode == localeCode) return data;
    return data.copyWith(localeCode: normalizeLocaleCode(localeCode));
  }

  AppData updateThemeMode(AppData data, String themeMode) {
    final normalized = normalizeThemeMode(themeMode);
    if (data.themeMode == normalized) return data;
    return data.copyWith(themeMode: normalized);
  }

  AppData updateThemeColorMode(AppData data, String mode) {
    final normalized = normalizeThemeColorMode(mode);
    if (data.themeColorMode == normalized) return data;
    return data.copyWith(themeColorMode: normalized);
  }

  AppData updateThemeSeedColorValue(AppData data, int colorValue) {
    if (data.themeSeedColorValue == colorValue) return data;
    return data.copyWith(themeSeedColorValue: colorValue);
  }

  AppData updateColorfulUiColorValue(AppData data, String key, int colorValue) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return data;
    if (data.colorfulUiColorValues[normalizedKey] == colorValue) return data;
    final updated = Map<String, int>.from(data.colorfulUiColorValues)
      ..[normalizedKey] = colorValue;
    return data.copyWith(colorfulUiColorValues: updated);
  }

  AppData updateColorfulCourseTextColorMode(AppData data, String mode) {
    final normalized = normalizeColorfulCourseTextColorMode(mode);
    if (data.colorfulCourseTextColorMode == normalized) return data;
    return data.copyWith(colorfulCourseTextColorMode: normalized);
  }

  AppData updateCourseNameColorValue(AppData data, String courseName, int colorValue) {
    final normalizedCourseName = normalizeCourseColorName(courseName);
    if (normalizedCourseName.isEmpty) return data;
    if (data.courseNameColorValues[normalizedCourseName] == colorValue) return data;
    final updated = Map<String, int>.from(data.courseNameColorValues)
      ..[normalizedCourseName] = colorValue;
    return data.copyWith(courseNameColorValues: updated);
  }

  AppData updateSchoolImportParserSource(AppData data, String source) {
    final normalized = normalizeSchoolImportParserSource(source);
    if (data.schoolImportParserSettings.source == normalized) return data;
    return data.copyWith(
      schoolImportParserSettings: data.schoolImportParserSettings.copyWith(
        source: normalized,
      ),
    );
  }

  AppData updateCustomSchoolImportBaseUrl(AppData data, String value) {
    final normalized = value.trim();
    if (data.schoolImportParserSettings.customBaseUrl == normalized) return data;
    return data.copyWith(
      schoolImportParserSettings: data.schoolImportParserSettings.copyWith(
        customBaseUrl: normalized,
      ),
    );
  }

  AppData updateCustomSchoolImportApiKey(AppData data, String value) {
    final normalized = value.trim();
    if (data.schoolImportParserSettings.customApiKey == normalized) return data;
    return data.copyWith(
      schoolImportParserSettings: data.schoolImportParserSettings.copyWith(
        customApiKey: normalized,
      ),
    );
  }

  AppData updateCustomSchoolImportModel(AppData data, String value) {
    final normalized = value.trim();
    if (data.schoolImportParserSettings.customModel == normalized) return data;
    return data.copyWith(
      schoolImportParserSettings: data.schoolImportParserSettings.copyWith(
        customModel: normalized,
      ),
    );
  }

  AppData updateCustomSchoolImportPrompt(AppData data, String value) {
    final normalized = value.trim();
    if (data.schoolImportParserSettings.customPrompt == normalized) return data;
    return data.copyWith(
      schoolImportParserSettings: data.schoolImportParserSettings.copyWith(
        customPrompt: normalized,
      ),
    );
  }

  AppData updateLiveCourseOutlineColorValue(AppData data, int colorValue) {
    if (data.liveCourseOutlineColorValue == colorValue) return data;
    return data.copyWith(liveCourseOutlineColorValue: colorValue);
  }

  AppData updateLiveCourseOutlineEnabled(AppData data, bool value) {
    if (data.liveCourseOutlineEnabled == value) return data;
    return data.copyWith(liveCourseOutlineEnabled: value);
  }

  AppData updateLiveCourseOutlineFollowTheme(AppData data, bool value) {
    if (data.liveCourseOutlineFollowTheme == value) return data;
    return data.copyWith(liveCourseOutlineFollowTheme: value);
  }

  AppData updateLiveCourseOutlineSettings(
    AppData data, {
    required bool enabled,
    required bool followTheme,
    required int colorValue,
    required bool customColorInitialized,
    required String mode,
    required double width,
  }) {
    final normalizedWidth = normalizeLiveCourseOutlineWidth(width);
    final normalizedMode = normalizeLiveCourseOutlineMode(mode);
    return data.copyWith(
      liveCourseOutlineEnabled: enabled,
      liveCourseOutlineFollowTheme: followTheme,
      liveCourseOutlineColorValue: colorValue,
      liveCourseOutlineCustomColorInitialized: customColorInitialized,
      liveCourseOutlineMode: normalizedMode,
      liveCourseOutlineWidth: normalizedWidth,
    );
  }

  AppData ignoreUpdateVersion(AppData data, String version) {
    final normalized = version.trim();
    if (normalized.isEmpty || data.ignoredUpdateVersion == normalized) return data;
    return data.copyWith(ignoredUpdateVersion: normalized);
  }

  AppData updateAvailableUpdateVersion(AppData data, String? version) {
    final normalized = version?.trim();
    final nextValue = normalized == null || normalized.isEmpty ? null : normalized;
    if (data.availableUpdateVersion == nextValue) return data;
    return data.copyWith(availableUpdateVersion: nextValue);
  }
}
