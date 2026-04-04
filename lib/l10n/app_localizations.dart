import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Classmate'**
  String get appTitle;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String weekLabel(int week);

  /// No description provided for @addCourse.
  ///
  /// In en, this message translates to:
  /// **'Add course'**
  String get addCourse;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @multiTimetableSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch timetables'**
  String get multiTimetableSwitch;

  /// No description provided for @currentTimetableWeeks.
  ///
  /// In en, this message translates to:
  /// **'Current timetable · {weeks} weeks'**
  String currentTimetableWeeks(int weeks);

  /// No description provided for @tapToSwitchWeeks.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch · {weeks} weeks'**
  String tapToSwitchWeeks(int weeks);

  /// No description provided for @editTimetable.
  ///
  /// In en, this message translates to:
  /// **'Edit timetable'**
  String get editTimetable;

  /// No description provided for @createTimetable.
  ///
  /// In en, this message translates to:
  /// **'New timetable'**
  String get createTimetable;

  /// No description provided for @jumpToWeek.
  ///
  /// In en, this message translates to:
  /// **'Jump to week'**
  String get jumpToWeek;

  /// No description provided for @timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get timetable;

  /// No description provided for @timetableName.
  ///
  /// In en, this message translates to:
  /// **'Timetable name'**
  String get timetableName;

  /// No description provided for @totalWeeks.
  ///
  /// In en, this message translates to:
  /// **'Total weeks'**
  String get totalWeeks;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteTimetableTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete timetable'**
  String get deleteTimetableTitle;

  /// No description provided for @deleteTimetableMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteTimetableMessage(Object name);

  /// No description provided for @noTimetableTitle.
  ///
  /// In en, this message translates to:
  /// **'No timetable yet'**
  String get noTimetableTitle;

  /// No description provided for @noTimetableMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a timetable or import one from a JSON file.'**
  String get noTimetableMessage;

  /// No description provided for @importTimetable.
  ///
  /// In en, this message translates to:
  /// **'Import timetable'**
  String get importTimetable;

  /// No description provided for @courseName.
  ///
  /// In en, this message translates to:
  /// **'Course name'**
  String get courseName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @dayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayOfWeek;

  /// No description provided for @semesterWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get semesterWeeks;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @linkedPeriods.
  ///
  /// In en, this message translates to:
  /// **'Linked periods'**
  String get linkedPeriods;

  /// No description provided for @linkedPeriodsUnmatched.
  ///
  /// In en, this message translates to:
  /// **'No periods matched for the current time. Tap to choose manually.'**
  String get linkedPeriodsUnmatched;

  /// No description provided for @periodRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period {start}-{end}'**
  String periodRangeLabel(int start, int end);

  /// No description provided for @teacherName.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherName;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @customFields.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get customFields;

  /// No description provided for @customFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'One per line, format: key:value'**
  String get customFieldsHint;

  /// No description provided for @selectDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Choose day'**
  String get selectDayOfWeek;

  /// No description provided for @selectSemesterWeeks.
  ///
  /// In en, this message translates to:
  /// **'Choose weeks'**
  String get selectSemesterWeeks;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @selectLinkedPeriods.
  ///
  /// In en, this message translates to:
  /// **'Choose linked periods'**
  String get selectLinkedPeriods;

  /// No description provided for @addCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add course'**
  String get addCourseTitle;

  /// No description provided for @editCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get editCourseTitle;

  /// No description provided for @editCourseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit course'**
  String get editCourseTooltip;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get place;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @notFilled.
  ///
  /// In en, this message translates to:
  /// **'Not filled'**
  String get notFilled;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @conflictCourses.
  ///
  /// In en, this message translates to:
  /// **'Conflicting courses'**
  String get conflictCourses;

  /// No description provided for @locationNotFilled.
  ///
  /// In en, this message translates to:
  /// **'Location not filled'**
  String get locationNotFilled;

  /// No description provided for @setAsDisplayed.
  ///
  /// In en, this message translates to:
  /// **'Set as displayed'**
  String get setAsDisplayed;

  /// No description provided for @editThisCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit this course'**
  String get editThisCourse;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @noTimetableSettings.
  ///
  /// In en, this message translates to:
  /// **'No timetable is currently available for settings.'**
  String get noTimetableSettings;

  /// No description provided for @semesterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Semester start date'**
  String get semesterStartDate;

  /// No description provided for @periodTimeSets.
  ///
  /// In en, this message translates to:
  /// **'Period time set'**
  String get periodTimeSets;

  /// No description provided for @noPeriodTimeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No available period time set'**
  String get noPeriodTimeAvailable;

  /// No description provided for @periodTimeSetSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} periods'**
  String periodTimeSetSummary(Object name, int count);

  /// No description provided for @coursePopupDismissSetting.
  ///
  /// In en, this message translates to:
  /// **'Allow outside tap to close course popup'**
  String get coursePopupDismissSetting;

  /// No description provided for @coursePopupDismissSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Turning this off also disables swipe-down dismissal.'**
  String get coursePopupDismissSettingHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @dataImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import and export data'**
  String get dataImportExport;

  /// No description provided for @dataImportExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Import full data or single timetables, or export current/all timetables.'**
  String get dataImportExportDesc;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceLicensesDesc.
  ///
  /// In en, this message translates to:
  /// **'View licenses for dependencies and app icon assets.'**
  String get openSourceLicensesDesc;

  /// No description provided for @githubRepository.
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get githubRepository;

  /// No description provided for @openGithubFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the GitHub repository link'**
  String get openGithubFailed;

  /// No description provided for @selectPeriodTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Choose period time set'**
  String get selectPeriodTimeSet;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @editPeriodTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Edit period time set'**
  String get editPeriodTimeSet;

  /// No description provided for @importTimetableFiles.
  ///
  /// In en, this message translates to:
  /// **'Import timetable'**
  String get importTimetableFiles;

  /// No description provided for @importTimetableFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports one or multiple timetable files.'**
  String get importTimetableFilesDesc;

  /// No description provided for @shareTimetableFiles.
  ///
  /// In en, this message translates to:
  /// **'Share timetable files'**
  String get shareTimetableFiles;

  /// No description provided for @shareTimetableFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more timetables first.'**
  String get shareTimetableFilesDesc;

  /// No description provided for @saveTimetableFiles.
  ///
  /// In en, this message translates to:
  /// **'Save timetable files'**
  String get saveTimetableFiles;

  /// No description provided for @saveTimetableFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more timetables first.'**
  String get saveTimetableFilesDesc;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @selectTimetablesToExport.
  ///
  /// In en, this message translates to:
  /// **'Choose timetables to export'**
  String get selectTimetablesToExport;

  /// No description provided for @selectTimetablesToImport.
  ///
  /// In en, this message translates to:
  /// **'Choose timetables to import'**
  String get selectTimetablesToImport;

  /// No description provided for @timetableCourseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} courses'**
  String timetableCourseCount(int count);

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @importTimetableDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import timetable'**
  String get importTimetableDialogTitle;

  /// No description provided for @chooseImportMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how to import.'**
  String get chooseImportMethod;

  /// No description provided for @importAsNewTimetable.
  ///
  /// In en, this message translates to:
  /// **'Import as new timetable'**
  String get importAsNewTimetable;

  /// No description provided for @replaceCurrentTimetable.
  ///
  /// In en, this message translates to:
  /// **'Replace current timetable'**
  String get replaceCurrentTimetable;

  /// No description provided for @savedToPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedToPath(Object path);

  /// No description provided for @saveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled'**
  String get saveCancelled;

  /// No description provided for @fileSaveRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'File saving restricted'**
  String get fileSaveRestrictedTitle;

  /// No description provided for @fileSaveRestrictedRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'The system could not save the file. You can retry or use sharing instead.'**
  String get fileSaveRestrictedRetryMessage;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get retrySave;

  /// No description provided for @fileSaveRestrictedSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable file access in system settings, then return and try exporting again.'**
  String get fileSaveRestrictedSettingsMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @browserDownloadRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Browser download restricted'**
  String get browserDownloadRestrictedTitle;

  /// No description provided for @browserDownloadRestrictedMessage.
  ///
  /// In en, this message translates to:
  /// **'This browser does not support directly saving to a local file. Check browser download permissions or use file sharing instead.'**
  String get browserDownloadRestrictedMessage;

  /// No description provided for @switchToShare.
  ///
  /// In en, this message translates to:
  /// **'Use sharing instead'**
  String get switchToShare;

  /// No description provided for @fileSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'File save failed'**
  String get fileSaveFailedTitle;

  /// No description provided for @fileSaveFailedWindowsMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to write to the current path. The target folder may be protected, the file may be in use, or the path may be unwritable.'**
  String get fileSaveFailedWindowsMessage;

  /// No description provided for @fileSaveFailedGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'The system could not save the file. You can retry, check system settings, or use file sharing instead.'**
  String get fileSaveFailedGenericMessage;

  /// No description provided for @retryLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get retryLater;

  /// No description provided for @exportSwitchedToShare.
  ///
  /// In en, this message translates to:
  /// **'Switched to file sharing for export'**
  String get exportSwitchedToShare;

  /// No description provided for @saveFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Please try again later.'**
  String get saveFailedRetry;

  /// No description provided for @importFailedCheckContent.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check the file content.'**
  String get importFailedCheckContent;

  /// No description provided for @noImportableTimetables.
  ///
  /// In en, this message translates to:
  /// **'No usable timetables were found in the imported file.'**
  String get noImportableTimetables;

  /// No description provided for @importedTimetablesCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} timetables'**
  String importedTimetablesCount(int count);

  /// No description provided for @periodTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Period times'**
  String get periodTimesTitle;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import and export'**
  String get importExport;

  /// No description provided for @importPeriodTemplate.
  ///
  /// In en, this message translates to:
  /// **'Import period template'**
  String get importPeriodTemplate;

  /// No description provided for @sharePeriodTemplate.
  ///
  /// In en, this message translates to:
  /// **'Share period template'**
  String get sharePeriodTemplate;

  /// No description provided for @saveTemplateToFile.
  ///
  /// In en, this message translates to:
  /// **'Save template to file'**
  String get saveTemplateToFile;

  /// No description provided for @deletePeriodTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Delete period time set'**
  String get deletePeriodTimeSet;

  /// No description provided for @periodTimeSetName.
  ///
  /// In en, this message translates to:
  /// **'Period time set name'**
  String get periodTimeSetName;

  /// No description provided for @addOnePeriod.
  ///
  /// In en, this message translates to:
  /// **'Add period'**
  String get addOnePeriod;

  /// No description provided for @periodNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Period {index}'**
  String periodNumberLabel(int index);

  /// No description provided for @deleteThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Delete this period'**
  String get deleteThisPeriod;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration {minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @gapFromPrevious.
  ///
  /// In en, this message translates to:
  /// **'Gap from previous {minutes} min'**
  String gapFromPrevious(int minutes);

  /// No description provided for @endTimeMustBeLater.
  ///
  /// In en, this message translates to:
  /// **'End time must be later than start time'**
  String get endTimeMustBeLater;

  /// No description provided for @periodOverlapPrevious.
  ///
  /// In en, this message translates to:
  /// **'This period overlaps the previous one'**
  String get periodOverlapPrevious;

  /// No description provided for @periodTimesSaved.
  ///
  /// In en, this message translates to:
  /// **'Period times saved'**
  String get periodTimesSaved;

  /// No description provided for @deletePeriodTimeSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete period time set'**
  String get deletePeriodTimeSetTitle;

  /// No description provided for @deletePeriodTimeSetMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deletePeriodTimeSetMessage(Object name);

  /// No description provided for @currentPeriodTimeSet.
  ///
  /// In en, this message translates to:
  /// **'current period time set'**
  String get currentPeriodTimeSet;

  /// No description provided for @importedPeriodTimesCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} period times'**
  String importedPeriodTimesCount(int count);

  /// No description provided for @periodFilePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'File permission needed'**
  String get periodFilePermissionTitle;

  /// No description provided for @androidFilePermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Android export requires file access permission. Grant permission to continue saving.'**
  String get androidFilePermissionMessage;

  /// No description provided for @reauthorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize again'**
  String get reauthorize;

  /// No description provided for @permissionPermanentlyDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission permanently denied'**
  String get permissionPermanentlyDeniedTitle;

  /// No description provided for @permissionSettingsExportMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable file access in system settings, then return and try exporting again.'**
  String get permissionSettingsExportMessage;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyEntryDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how the app handles local data, import/export, and external links.'**
  String get privacyPolicyEntryDesc;

  /// No description provided for @privacyPolicyAcceptedVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Accepted version: {version}'**
  String privacyPolicyAcceptedVersionLabel(Object version);

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'Classmate currently works as a local-first app. Timetable data, timetable settings, and period-time data are stored on your device or in your browser by default. The app only uses system capabilities such as import, export, sharing, or opening external links when you explicitly trigger those actions.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyPolicyLocalStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get privacyPolicyLocalStorageTitle;

  /// No description provided for @privacyPolicyLocalStorageBody.
  ///
  /// In en, this message translates to:
  /// **'On Android, iOS, Windows, macOS, and Linux, the app stores timetable data and related settings in a local file named classmate_data.json inside the app documents directory. On the web, the app stores the same kind of data in browser storage. The app does not upload this data to a developer-controlled server by default.'**
  String get privacyPolicyLocalStorageBody;

  /// No description provided for @privacyPolicyImportExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import and export'**
  String get privacyPolicyImportExportTitle;

  /// No description provided for @privacyPolicyImportExportBody.
  ///
  /// In en, this message translates to:
  /// **'The app only reads or writes timetable JSON files and period-template files when you explicitly choose a file or start an export action. Imported file contents are only used to create or update timetable data locally.'**
  String get privacyPolicyImportExportBody;

  /// No description provided for @privacyPolicySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get privacyPolicySharingTitle;

  /// No description provided for @privacyPolicySharingBody.
  ///
  /// In en, this message translates to:
  /// **'When you explicitly use sharing, the app passes the exported file to the system share sheet or to the target app you choose. How that file is handled afterward depends on the target app or service you selected.'**
  String get privacyPolicySharingBody;

  /// No description provided for @privacyPolicyExternalLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'External links'**
  String get privacyPolicyExternalLinksTitle;

  /// No description provided for @privacyPolicyExternalLinksBody.
  ///
  /// In en, this message translates to:
  /// **'When you open external links such as the GitHub repository, the app hands the action off to your browser or another external application. Data handling after that point is governed by the third party you open.'**
  String get privacyPolicyExternalLinksBody;

  /// No description provided for @privacyPolicyNoCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What is not collected right now'**
  String get privacyPolicyNoCollectionTitle;

  /// No description provided for @privacyPolicyNoCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'In the current version, the app does not require an account and does not collect school account passwords, cloud backup data, advertising identifiers, or analytics data by default.'**
  String get privacyPolicyNoCollectionBody;

  /// No description provided for @privacyPolicyFutureFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Future feature notice'**
  String get privacyPolicyFutureFeatureTitle;

  /// No description provided for @privacyPolicyFutureFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'A future version may support importing courses from a school timetable webpage when you explicitly start that process. If that feature introduces new data handling, network requests, or additional information requirements, this policy will be updated before the feature is released.'**
  String get privacyPolicyFutureFeatureBody;

  /// No description provided for @privacyPolicyUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Policy updates'**
  String get privacyPolicyUpdatesTitle;

  /// No description provided for @privacyPolicyUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'The current privacy policy version is {version}. If a future version changes how data is handled, the app may ask you to read and agree to the updated policy again.'**
  String privacyPolicyUpdatesBody(Object version);

  /// No description provided for @privacyGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the privacy policy before using the app'**
  String get privacyGateTitle;

  /// No description provided for @privacyGateSummaryStorage.
  ///
  /// In en, this message translates to:
  /// **'Timetables and settings are stored locally by default and are not automatically uploaded to a developer server.'**
  String get privacyGateSummaryStorage;

  /// No description provided for @privacyGateSummaryImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import, export, and sharing only happen when you explicitly start them.'**
  String get privacyGateSummaryImportExport;

  /// No description provided for @privacyGateSummaryExternal.
  ///
  /// In en, this message translates to:
  /// **'Opening GitHub or other external links hands the action to your browser or another app.'**
  String get privacyGateSummaryExternal;

  /// No description provided for @privacyGateSummaryUpdates.
  ///
  /// In en, this message translates to:
  /// **'If future features such as webpage import change data handling, the privacy policy will be updated first.'**
  String get privacyGateSummaryUpdates;

  /// No description provided for @privacyViewFullPolicy.
  ///
  /// In en, this message translates to:
  /// **'View full privacy policy'**
  String get privacyViewFullPolicy;

  /// No description provided for @privacyAgreeAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get privacyAgreeAndContinue;

  /// No description provided for @privacyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get privacyDecline;

  /// No description provided for @privacyDeclineWebHint.
  ///
  /// In en, this message translates to:
  /// **'This browser environment does not allow the app to close the page for you. If you do not agree, please close this tab or window yourself.'**
  String get privacyDeclineWebHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
