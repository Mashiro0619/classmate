import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/school_import_models.dart';
import '../models/timetable_models.dart';
import '../providers/timetable_provider.dart';
import 'period_time_set_picker_dialog.dart';

class SchoolWebImportResult {
  const SchoolWebImportResult({
    required this.response,
    required this.mode,
    required this.selectedPeriodTimeSetId,
  });

  final SchoolImportResponse response;
  final TimetableImportMode mode;
  final String selectedPeriodTimeSetId;
}

class SchoolWebImportResultSheet extends StatefulWidget {
  const SchoolWebImportResultSheet({
    super.key,
    required this.response,
    required this.canReplaceCurrent,
    required this.periodTimeSets,
    required this.initialPeriodTimeSetId,
    required this.provider,
  });

  final SchoolImportResponse response;
  final bool canReplaceCurrent;
  final List<PeriodTimeSet> periodTimeSets;
  final String initialPeriodTimeSetId;
  final TimetableProvider provider;

  @override
  State<SchoolWebImportResultSheet> createState() =>
      _SchoolWebImportResultSheetState();
}

class _SchoolWebImportResultSheetState extends State<SchoolWebImportResultSheet> {
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late String _selectedPeriodTimeSetId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.response.timetable.name)
      ..addListener(_handleNameChanged);
    _startDate = DateTime(2026, 3, 2);
    _selectedPeriodTimeSetId = widget.periodTimeSets.any(
          (item) => item.id == widget.initialPeriodTimeSetId,
        )
        ? widget.initialPeriodTimeSetId
        : (widget.periodTimeSets.isEmpty ? '' : widget.periodTimeSets.first.id);
  }

  void _handleNameChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timetable = widget.response.timetable;
    final warnings = widget.response.meta.warnings;
    final theme = Theme.of(context);
    PeriodTimeSet? selectedPeriodTimeSet;
    for (final item in widget.periodTimeSets) {
      if (item.id == _selectedPeriodTimeSetId) {
        selectedPeriodTimeSet = item;
        break;
      }
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.schoolWebImportPreview,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.timetableName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.semesterStartDate),
                    subtitle: Text(_formatDate(_startDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickStartDate,
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _nameController.text.trim().isEmpty
                          ? l10n.none
                          : _nameController.text.trim(),
                    ),
                    subtitle: Text(
                      '${l10n.schoolWebImportCourseCount(timetable.courses.length)} · '
                      '${selectedPeriodTimeSet == null ? l10n.noPeriodTimeAvailable : l10n.periodTimeSetSummary(selectedPeriodTimeSet.name, selectedPeriodTimeSet.periodTimes.length)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.selectPeriodTimeSet),
                    subtitle: Text(
                      selectedPeriodTimeSet == null
                          ? l10n.noPeriodTimeAvailable
                          : l10n.periodTimeSetSummary(
                              selectedPeriodTimeSet.name,
                              selectedPeriodTimeSet.periodTimes.length,
                            ),
                    ),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: widget.periodTimeSets.isEmpty
                        ? null
                        : () async {
                            final result = await showPeriodTimeSetPickerDialog(
                              context,
                              provider: widget.provider,
                              selectedPeriodTimeSetId: _selectedPeriodTimeSetId,
                            );
                            if (!mounted || result == null) {
                              return;
                            }
                            setState(() => _selectedPeriodTimeSetId = result);
                          },
                  ),
                  if (widget.response.meta.pageTitle.trim().isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.schoolWebImportPageTitleLabel),
                      subtitle: Text(widget.response.meta.pageTitle),
                    ),
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.schoolWebImportWarnings,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.info_outline, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                      OutlinedButton(
                        onPressed: _selectedPeriodTimeSetId.isEmpty
                            ? null
                            : () => _submit(TimetableImportMode.addAsNew),
                        child: Text(l10n.importAsNewTimetable),
                      ),
                      if (widget.canReplaceCurrent)
                        FilledButton(
                          onPressed: _selectedPeriodTimeSetId.isEmpty
                              ? null
                              : () => _submit(TimetableImportMode.replaceActive),
                          child: Text(l10n.replaceCurrentTimetable),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _startDate,
    );
    if (picked == null) {
      return;
    }
    setState(() => _startDate = picked);
  }

  void _submit(TimetableImportMode mode) {
    final editedName = _nameController.text.trim();
    final nextResponse = widget.response.copyWith(
      timetable: widget.response.timetable.copyWith(
        name: editedName,
        startDate: _startDate,
      ),
    );
    Navigator.of(context).pop(
      SchoolWebImportResult(
        response: nextResponse,
        mode: mode,
        selectedPeriodTimeSetId: _selectedPeriodTimeSetId,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
