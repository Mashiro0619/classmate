import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import '../services/export_service.dart';
import 'period_times_page.dart';
import 'privacy_policy_page.dart';

enum _DataAction {
  importTimetables,
  exportTimetablesShare,
  exportTimetablesSave,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _exportService = ExportService();

  String? _editingTimetableId;
  late DateTime _selectedDate;
  late String _selectedPeriodTimeSetId;

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
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                contentPadding: EdgeInsets.zero,
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: provider.closeCoursePopupOnOutsideTap,
                title: Text(l10n.coursePopupDismissSetting),
                subtitle: Text(l10n.coursePopupDismissSettingHint),
                onChanged: provider.updateCloseCoursePopupOnOutsideTap,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.language),
                subtitle: Text(
                  provider.localeCode == 'en'
                      ? l10n.languageEnglish
                      : l10n.languageChinese,
                ),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickLanguage(provider),
              ),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.import_export),
                title: Text(l10n.dataImportExport),
                subtitle: Text(l10n.dataImportExportDesc),
                onTap: () => _showDataActions(provider),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.openSourceLicenses),
                subtitle: Text(l10n.openSourceLicensesDesc),
                onTap: _openLicensesPage,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.languageChinese),
                trailing: provider.localeCode == 'zh'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop('zh'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
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
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, refreshDialog) {
            final currentSelectedId = _selectedPeriodTimeSetId;
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(child: Text(l10n.selectPeriodTimeSet)),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await provider.addPeriodTimeSet();
                      if (!mounted) {
                        return;
                      }
                      setState(() => _selectedPeriodTimeSetId = created.id);
                      await _openPeriodTimePage(provider, created.id);
                      if (!mounted) {
                        return;
                      }
                      refreshDialog(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newItem),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.periodTimeSets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = provider.periodTimeSets[index];
                    final selected = item.id == currentSelectedId;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: selected
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      title: Text(item.name),
                      subtitle: Text(
                        l10n.periodTimeSetSummary(
                          item.name,
                          item.periodTimes.length,
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (selected) const Icon(Icons.check),
                          IconButton(
                            tooltip: l10n.editPeriodTimeSet,
                            onPressed: () async {
                              await _openPeriodTimePage(provider, item.id);
                              if (!mounted) {
                                return;
                              }
                              final stillExists =
                                  provider.periodTimeSetForId(item.id) != null;
                              if (!stillExists &&
                                  _selectedPeriodTimeSetId == item.id) {
                                final fallbackId =
                                    provider.activePeriodTimeSetOrNull?.id ??
                                    '';
                                setState(
                                  () => _selectedPeriodTimeSetId = fallbackId,
                                );
                              }
                              refreshDialog(() {});
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(item.id),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            );
          },
        );
      },
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

  Future<void> _openGithubRepo() async {
    final uri = Uri.parse('https://github.com/Mashiro0619/classmate');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage(AppLocalizations.of(context)!.openGithubFailed);
    }
  }

  Future<void> _openPeriodTimePage(
    TimetableProvider provider,
    String periodTimeSetId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: PeriodTimesPage(periodTimeSetId: periodTimeSetId),
        ),
      ),
    );
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
        await _importTimetables(provider);
        return;
      case _DataAction.exportTimetablesShare:
        await _exportTimetables(provider, share: true);
        return;
      case _DataAction.exportTimetablesSave:
        await _exportTimetables(provider, share: false);
        return;
    }
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

  Future<void> _importTimetables(TimetableProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _pickJsonSource();
    if (source == null || !mounted) {
      return;
    }

    List<TimetableData> candidates;
    try {
      candidates = provider.previewImportTimetables(source);
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    } catch (_) {
      _showMessage(l10n.importFailedCheckContent);
      return;
    }

    if (candidates.isEmpty) {
      _showMessage(l10n.noImportableTimetables);
      return;
    }

    final selectedIds = candidates.length == 1
        ? [candidates.first.id]
        : await _pickTimetableIds(
            timetables: candidates,
            title: l10n.selectTimetablesToImport,
            confirmText: l10n.importAction,
            initialSelectedIds: candidates.map((item) => item.id).toList(),
          );
    if (selectedIds == null || selectedIds.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    var mode = TimetableImportMode.addAsNew;
    if (selectedIds.length == 1 && provider.activeTimetableOrNull != null) {
      final pickedMode = await showDialog<TimetableImportMode>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.importTimetableDialogTitle),
            content: Text(l10n.chooseImportMethod),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(TimetableImportMode.addAsNew),
                child: Text(l10n.importAsNewTimetable),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(TimetableImportMode.replaceActive),
                child: Text(l10n.replaceCurrentTimetable),
              ),
            ],
          );
        },
      );
      if (pickedMode == null) {
        return;
      }
      mode = pickedMode;
    }

    try {
      final count = await provider.importSelectedTimetablesJson(
        source,
        timetableIds: selectedIds,
        mode: mode,
      );
      if (mounted) {
        _showMessage(l10n.importedTimetablesCount(count));
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.importFailedCheckContent);
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

  Future<String?> _pickJsonSource() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }
    return utf8.decode(bytes);
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
