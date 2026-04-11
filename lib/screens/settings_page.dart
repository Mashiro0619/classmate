import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../services/export_service.dart';
import '../services/update_service.dart';
import '../widgets/period_time_set_picker_dialog.dart';
import 'privacy_policy_page.dart';
import 'theme_settings_page.dart';
import 'timetable_import_flow.dart';

enum _DataAction {
  importTimetables,
  exportTimetablesShare,
  exportTimetablesSave,
}

enum UpdateCheckSource { manual, startup }

enum _UpdateAction { github, website, ignore, cancel }

class AppUpdateCoordinator {
  static const _updateService = UpdateService();

  static Future<void> checkForUpdates(
    BuildContext context, {
    required TimetableProvider provider,
    required UpdateCheckSource source,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await _updateService.checkForUpdates();
      if (!context.mounted) {
        return;
      }
      final latestMessage = l10n.alreadyLatestVersion(result.localVersion);
      if (!result.hasUpdate) {
        await provider.updateAvailableUpdateVersion(null);
        if (!context.mounted) {
          return;
        }
        if (source == UpdateCheckSource.manual) {
          _showMessage(context, latestMessage);
        }
        return;
      }
      await provider.updateAvailableUpdateVersion(result.remoteVersion);
      if (!context.mounted) {
        return;
      }
      if (source == UpdateCheckSource.startup &&
          provider.ignoredUpdateVersion == result.remoteVersion) {
        return;
      }
      final action = await _showUpdateDialog(
        context,
        result,
        showIgnoreButton: source == UpdateCheckSource.startup,
      );
      if (!context.mounted) {
        return;
      }
      switch (action) {
        case _UpdateAction.github:
          await _openReleasesPage(context, result.releaseUrl);
          return;
        case _UpdateAction.website:
          await _openWebsitePage(context, result.officialWebsiteUrl);
          return;
        case _UpdateAction.ignore:
          if (source == UpdateCheckSource.startup) {
            await provider.ignoreUpdateVersion(result.remoteVersion);
          }
          return;
        case _UpdateAction.cancel:
        case null:
          return;
      }
    } catch (_) {
      if (context.mounted && source == UpdateCheckSource.manual) {
        _showMessage(context, l10n.openUpdatesFailed);
      }
    }
  }

  static Future<_UpdateAction?> _showUpdateDialog(
    BuildContext context,
    UpdateCheckResult result, {
    required bool showIgnoreButton,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final updateContent = result.updateContent.trim();
    return showDialog<_UpdateAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.checkForUpdates),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.currentVersionLabel} ${result.localVersion}'),
                const SizedBox(height: 8),
                Text('${l10n.latestVersionLabel} ${result.remoteVersion}'),
                if (updateContent.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.updateContentLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(updateContent),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_UpdateAction.cancel),
              child: Text(l10n.cancel),
            ),
            if (showIgnoreButton)
              TextButton(
                onPressed: () => Navigator.of(context).pop(_UpdateAction.ignore),
                child: Text(l10n.ignoreThisVersion),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_UpdateAction.website),
              child: Text(l10n.officialWebsite),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_UpdateAction.github),
              child: const Text('GitHub'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openReleasesPage(
    BuildContext context, [
    String? releaseUrl,
  ]) async {
    final uri = Uri.parse(
      releaseUrl ?? 'https://github.com/Mashiro0619/classmate/releases/latest',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showMessage(context, AppLocalizations.of(context)!.openUpdatesFailed);
    }
  }

  static Future<void> _openWebsitePage(
    BuildContext context,
    String websiteUrl,
  ) async {
    final uri = Uri.parse(websiteUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showMessage(context, AppLocalizations.of(context)!.openUpdatesFailed);
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _exportService = ExportService();

  String? _editingTimetableId;
  String _currentVersion = '';
  late DateTime _selectedDate;
  late String _selectedPeriodTimeSetId;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<TimetableProvider>();
    final timetable = provider.activeTimetableOrNull;
    if (timetable == null) {
      return;
    }
    if (_editingTimetableId == timetable.id) {
      return;
    }
    _editingTimetableId = timetable.id;
    _selectedDate = timetable.config.startDate;
    _selectedPeriodTimeSetId = timetable.config.periodTimeSetId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context)!;
        final timetable = provider.activeTimetableOrNull;
        if (timetable == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.settingsTitle)),
            body: Center(child: Text(l10n.noTimetableSettings)),
          );
        }
        final selectedSet =
            provider.periodTimeSetForId(_selectedPeriodTimeSetId) ??
            provider.activePeriodTimeSetOrNull;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(l10n.semesterStartDate),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _pickStartDate(provider, timetable.config),
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l10n.periodTimeSets),
                subtitle: Text(
                  selectedSet == null
                      ? l10n.noPeriodTimeAvailable
                      : l10n.periodTimeSetSummary(
                          selectedSet.name,
                          selectedSet.periodTimes.length,
                        ),
                ),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickPeriodTimeSet(provider, timetable.config),
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.language_outlined),
                title: Text(l10n.schoolWebImportEntry),
                subtitle: Text(l10n.schoolWebImportEntryDesc),
                onTap: () => _openSchoolSitesPage(provider),
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.theme),
                subtitle: Text(
                  switch (provider.themeMode) {
                    'dark' => l10n.themeDark,
                    'system' => l10n.themeFollowSystem,
                    _ => l10n.themeLight,
                  },
                ),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => _openThemeSettingsPage(provider),
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.closeCoursePopupOnOutsideTap,
                title: Text(l10n.coursePopupDismissSetting),
                subtitle: Text(l10n.coursePopupDismissSettingHint),
                onChanged: provider.updateCloseCoursePopupOnOutsideTap,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.preserveTimetableGaps,
                title: Text(l10n.preserveTimetableGaps),
                subtitle: Text(l10n.preserveTimetableGapsHint),
                onChanged: provider.updatePreserveTimetableGaps,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.showPastEndedCourses,
                title: Text(l10n.showPastEndedCourses),
                subtitle: Text(l10n.showPastEndedCoursesHint),
                onChanged: provider.updateShowPastEndedCourses,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                value: provider.showFutureCourses,
                title: Text(l10n.showFutureCourses),
                subtitle: Text(l10n.showFutureCoursesHint),
                onChanged: provider.updateShowFutureCourses,
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.translate_outlined),
                title: Text(l10n.language),
                subtitle: Text(
                  provider.localeCode == 'en'
                      ? l10n.languageEnglish
                      : l10n.languageChinese,
                ),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickLanguage(provider),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.import_export),
                title: Text(l10n.dataImportExport),
                subtitle: Text(l10n.dataImportExportDesc),
                onTap: () => _showDataActions(provider),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicyTitle),
                subtitle: Text(
                  provider.acceptedPrivacyPolicyVersion == null
                      ? l10n.privacyPolicyEntryDesc
                      : l10n.privacyPolicyAcceptedVersionLabel(
                          provider.acceptedPrivacyPolicyVersion!,
                        ),
                ),
                onTap: _openPrivacyPolicyPage,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.openSourceLicenses),
                subtitle: Text(l10n.openSourceLicensesDesc),
                onTap: _openLicensesPage,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.update_outlined),
                title: Text(l10n.checkForUpdates),
                subtitle: Text(_buildUpdateSubtitle(provider, l10n)),
                onTap: _checkForUpdates,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const FaIcon(FontAwesomeIcons.github),
                title: Text(l10n.githubRepository),
                subtitle: const Text('github.com/Mashiro0619/classmate'),
                onTap: _openGithubRepo,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openThemeSettingsPage(TimetableProvider provider) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const ThemeSettingsPage(),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(TimetableProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.languageChinese),
                trailing: provider.localeCode == 'zh'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop('zh'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.languageEnglish),
                trailing: provider.localeCode == 'en'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop('en'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
    if (result == null || result == provider.localeCode) {
      return;
    }
    await provider.updateLocaleCode(result);
  }

  Future<void> _pickPeriodTimeSet(
    TimetableProvider provider,
    TimetableConfig config,
  ) async {
    final result = await showPeriodTimeSetPickerDialog(
      context,
      provider: provider,
      selectedPeriodTimeSetId: _selectedPeriodTimeSetId,
    );
    if (result == null || result == _selectedPeriodTimeSetId) {
      return;
    }
    setState(() => _selectedPeriodTimeSetId = result);
    await provider.updateTimetableConfig(
      config.copyWith(periodTimeSetId: result),
    );
  }

  Future<void> _pickStartDate(
    TimetableProvider provider,
    TimetableConfig config,
  ) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
    );
    if (picked == null || picked == _selectedDate) {
      return;
    }
    setState(() => _selectedDate = picked);
    await provider.updateTimetableConfig(config.copyWith(startDate: picked));
  }

  Future<void> _openPrivacyPolicyPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _openLicensesPage() {
    showLicensePage(context: context, applicationName: 'Classmate');
  }

  String _buildUpdateSubtitle(
    TimetableProvider provider,
    AppLocalizations l10n,
  ) {
    final versionLabel = _currentVersion.isEmpty
        ? l10n.currentVersionLabel
        : '${l10n.currentVersionLabel} $_currentVersion';
    final availableUpdateVersion = provider.availableUpdateVersion;
    if (availableUpdateVersion == null ||
        availableUpdateVersion.isEmpty ||
        !_isNewerThanCurrentVersion(availableUpdateVersion)) {
      return versionLabel;
    }
    return '$versionLabel · ${l10n.newVersionAvailable}';
  }

  Future<void> _loadCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    final currentVersion = info.version;
    setState(() => _currentVersion = currentVersion);
    final provider = context.read<TimetableProvider>();
    final availableUpdateVersion = provider.availableUpdateVersion;
    if (availableUpdateVersion != null &&
        availableUpdateVersion.isNotEmpty &&
        _compareVersions(availableUpdateVersion, currentVersion) <= 0) {
      await provider.updateAvailableUpdateVersion(null);
    }
  }

  Future<void> _checkForUpdates() {
    return AppUpdateCoordinator.checkForUpdates(
      context,
      provider: context.read<TimetableProvider>(),
      source: UpdateCheckSource.manual,
    );
  }

  bool _isNewerThanCurrentVersion(String version) {
    if (_currentVersion.isEmpty) {
      return true;
    }
    return _compareVersions(version, _currentVersion) > 0;
  }

  int _compareVersions(String a, String b) {
    final aParts = _normalizeVersion(a)
        .split('.')
        .map((item) => int.tryParse(item) ?? 0)
        .toList();
    final bParts = _normalizeVersion(b)
        .split('.')
        .map((item) => int.tryParse(item) ?? 0)
        .toList();
    final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var index = 0; index < maxLength; index++) {
      final left = index < aParts.length ? aParts[index] : 0;
      final right = index < bParts.length ? bParts[index] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }

  String _normalizeVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed.substring(1)
        : trimmed;
    return withoutPrefix.split('+').first.trim();
  }

  Future<void> _openGithubRepo() async {
    final uri = Uri.parse('https://github.com/Mashiro0619/classmate');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage(AppLocalizations.of(context)!.openGithubFailed);
    }
  }

  Future<void> _showDataActions(TimetableProvider provider) async {
    final action = await showModalBottomSheet<_DataAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return _buildAdaptiveBottomSheet(
          sheetContext,
          maxWidth: 680,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(l10n.importTimetableFiles),
                  subtitle: Text(l10n.importTimetableFilesDesc),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DataAction.importTimetables),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(l10n.shareTimetableFiles),
                  subtitle: Text(l10n.shareTimetableFilesDesc),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DataAction.exportTimetablesShare),
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_outlined),
                  title: Text(l10n.saveTimetableFiles),
                  subtitle: Text(l10n.saveTimetableFilesDesc),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DataAction.exportTimetablesSave),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) {
      return;
    }
    switch (action) {
      case _DataAction.importTimetables:
        await TimetableImportFlow.importTimetables(context, provider);
        return;
      case _DataAction.exportTimetablesShare:
        await _exportTimetables(provider, share: true);
        return;
      case _DataAction.exportTimetablesSave:
        await _exportTimetables(provider, share: false);
        return;
    }
  }

  Future<void> _openSchoolSitesPage(TimetableProvider provider) async {
    await TimetableImportFlow.openSchoolSitesPage(context, provider);
  }

  Future<void> _exportTimetables(
    TimetableProvider provider, {
    required bool share,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final activeId = provider.activeTimetableOrNull?.id;
    final selectedIds = await _pickTimetableIds(
      timetables: provider.timetables,
      title: l10n.selectTimetablesToExport,
      confirmText: share ? l10n.share : l10n.save,
      initialSelectedIds: activeId == null ? const [] : [activeId],
    );
    if (selectedIds == null || selectedIds.isEmpty) {
      return;
    }
    try {
      final content = provider.exportSelectedTimetablesJson(selectedIds);
      const fileName = 'classmate_timetables.json';
      if (share) {
        await _shareJson(fileName, content);
      } else {
        await _saveJsonToFile(fileName, content);
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.saveFailedRetry);
      }
    }
  }


  Future<List<String>?> _pickTimetableIds({
    required List<TimetableData> timetables,
    required String title,
    required String confirmText,
    List<String> initialSelectedIds = const [],
  }) {
    final draft = <String>{
      ...initialSelectedIds.where(
        (id) => timetables.any((item) => item.id == id),
      ),
    };
    if (draft.isEmpty && timetables.isNotEmpty) {
      draft.add(timetables.first.id);
    }
    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              draft
                                ..clear()
                                ..addAll(timetables.map((item) => item.id));
                            }),
                            child: Text(l10n.selectAll),
                          ),
                          TextButton(
                            onPressed: () => setState(draft.clear),
                            child: Text(l10n.clear),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: timetables.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final timetable = timetables[index];
                          final selected = draft.contains(timetable.id);
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: selected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                : null,
                            title: Text(timetable.config.name),
                            subtitle: Text(
                              l10n.timetableCourseCount(
                                timetable.courses.length,
                              ),
                            ),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  draft.remove(timetable.id);
                                } else {
                                  draft.add(timetable.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: draft.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(
                          timetables
                              .where((item) => draft.contains(item.id))
                              .map((item) => item.id)
                              .toList(),
                        ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _shareJson(String fileName, String content) async {
    await _exportService.shareFile(
      ExportPayload(fileName: fileName, content: content),
    );
  }

  Future<void> _saveJsonToFile(String fileName, String content) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _exportService.saveFile(
      ExportPayload(fileName: fileName, content: content),
    );
    if (!mounted) {
      return;
    }

    switch (result.status) {
      case ExportSaveStatus.saved:
        _showMessage(l10n.savedToPath(result.path ?? fileName));
        return;
      case ExportSaveStatus.cancelled:
        _showMessage(l10n.saveCancelled);
        return;
      case ExportSaveStatus.permissionDenied:
        final retry = await _showPermissionDialog(
          title: l10n.fileSaveRestrictedTitle,
          message: l10n.fileSaveRestrictedRetryMessage,
          confirmText: l10n.retrySave,
        );
        if (retry == true && mounted) {
          await _saveJsonToFile(fileName, content);
        }
        return;
      case ExportSaveStatus.permissionPermanentlyDenied:
        final openSettings = await _showPermissionDialog(
          title: l10n.fileSaveRestrictedTitle,
          message: l10n.fileSaveRestrictedSettingsMessage,
          confirmText: l10n.openSettings,
        );
        if (openSettings == true) {
          await _exportService.openSettings();
        }
        return;
      case ExportSaveStatus.unsupported:
        final shouldShare = await _showFailureDialog(
          title: l10n.browserDownloadRestrictedTitle,
          message: l10n.browserDownloadRestrictedMessage,
        );
        if (shouldShare == true) {
          await _shareJson(fileName, content);
          if (mounted) {
            _showMessage(l10n.exportSwitchedToShare);
          }
        }
        return;
      case ExportSaveStatus.failed:
        final shouldShare = await _showFailureDialog(
          title: _exportService.isWindows
              ? l10n.fileSaveFailedTitle
              : l10n.fileSaveRestrictedTitle,
          message: _exportService.isWindows
              ? l10n.fileSaveFailedWindowsMessage
              : l10n.fileSaveFailedGenericMessage,
        );
        if (shouldShare == true) {
          await _shareJson(fileName, content);
          if (mounted) {
            _showMessage(l10n.exportSwitchedToShare);
          }
        } else if (mounted) {
          _showMessage(l10n.saveFailedRetry);
        }
        return;
    }
  }

  Future<bool?> _showPermissionDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showFailureDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.retryLater),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.switchToShare),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAdaptiveBottomSheet(
    BuildContext context, {
    required Widget child,
    required double maxWidth,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLike = width >= 900;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktopLike ? maxWidth : width,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}
