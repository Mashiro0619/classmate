import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import 'school_sites_page.dart';

class TimetableImportFlow {
  const TimetableImportFlow._();

  static Future<void> importTimetables(
    BuildContext context,
    TimetableProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _pickJsonSource();
    if (source == null || !context.mounted) {
      return;
    }

    List<TimetableData> candidates;
    try {
      candidates = provider.previewImportTimetables(source);
    } on FormatException catch (error) {
      _showMessage(context, error.message);
      return;
    } catch (_) {
      _showMessage(context, l10n.importFailedCheckContent);
      return;
    }

    if (candidates.isEmpty) {
      _showMessage(context, l10n.noImportableTimetables);
      return;
    }

    final selectedIds = candidates.length == 1
        ? [candidates.first.id]
        : await _pickTimetableIds(
            context,
            timetables: candidates,
            title: l10n.selectTimetablesToImport,
            confirmText: l10n.importAction,
            initialSelectedIds: candidates.map((item) => item.id).toList(),
          );
    if (selectedIds == null || selectedIds.isEmpty || !context.mounted) {
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
      if (context.mounted) {
        _showMessage(context, l10n.importedTimetablesCount(count));
      }
    } on FormatException catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, l10n.importFailedCheckContent);
      }
    }
  }

  static Future<void> openSchoolSitesPage(
    BuildContext context,
    TimetableProvider provider,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TimetableProvider>.value(
          value: provider,
          child: const SchoolSitesPage(),
        ),
      ),
    );
  }

  static Future<List<String>?> _pickTimetableIds(
    BuildContext context, {
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
                                ? Theme.of(context).colorScheme.secondaryContainer
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

  static Future<String?> _pickJsonSource() async {
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

  static void _showMessage(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
