import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/school_import_models.dart';
import '../providers/timetable_provider.dart';
import '../services/school_import_api.dart';
import '../services/school_import_content_sanitizer.dart';
import '../widgets/school_web_import_result_sheet.dart';

class SchoolHtmlImportPage extends StatefulWidget {
  const SchoolHtmlImportPage({
    super.key,
    this.initialContent = '',
    this.initialUrl = '',
    this.initialTitle = '',
    this.showReturnToWebPageButton = false,
  });

  final String initialContent;
  final String initialUrl;
  final String initialTitle;
  final bool showReturnToWebPageButton;

  @override
  State<SchoolHtmlImportPage> createState() => _SchoolHtmlImportPageState();
}

class _SchoolHtmlImportPageState extends State<SchoolHtmlImportPage> {
  final SchoolImportApi _api = const SchoolImportApi();
  final TextEditingController _htmlController = TextEditingController();

  bool _isSubmitting = false;
  bool _isCompressed = false;

  bool get _isConfigured => AppConfig.hasSchoolImportApiBaseUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent.isNotEmpty) {
      _htmlController.text = widget.initialContent;
    }
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.schoolHtmlImportPageTitle),
        actions: [
          if (widget.showReturnToWebPageButton)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.schoolHtmlImportReturnToWebPage),
            ),
        ],
      ),
      body: !_isConfigured
          ? _buildMessage(l10n.schoolWebImportConfigMissing)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _htmlController,
                  enabled: !_isSubmitting,
                  onChanged: (_) {
                    if (_isCompressed) {
                      setState(() => _isCompressed = false);
                    }
                  },
                  minLines: 12,
                  maxLines: 20,
                  decoration: InputDecoration(
                    labelText: l10n.schoolHtmlImportHtmlLabel,
                    hintText: l10n.schoolHtmlImportHtmlHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: _isSubmitting ? null : _compressContent,
                  icon: Icon(
                    _isCompressed ? Icons.check_circle_outline : Icons.compress,
                  ),
                  label: Text(
                    _isCompressed
                        ? l10n.schoolHtmlImportCompressed
                        : l10n.schoolHtmlImportCompress,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting || !_isCompressed ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(l10n.schoolHtmlImportSubmit),
                ),
              ],
            ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _compressContent() async {
    final l10n = AppLocalizations.of(context)!;
    final html = _htmlController.text.trim();
    if (html.isEmpty) {
      _showMessage(l10n.schoolHtmlImportEmpty);
      return;
    }
    final sanitizedContent = SchoolImportContentSanitizer.sanitize(html);
    if (sanitizedContent.isEmpty) {
      _showMessage(l10n.schoolHtmlImportEmpty);
      return;
    }
    _htmlController.value = TextEditingValue(
      text: sanitizedContent,
      selection: TextSelection.collapsed(offset: sanitizedContent.length),
    );
    setState(() => _isCompressed = true);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<TimetableProvider>();
    final localeCode = provider.localeCode;
    final canReplaceCurrent = provider.activeTimetableOrNull != null;
    final html = _htmlController.text.trim();
    if (html.isEmpty) {
      _showMessage(l10n.schoolHtmlImportEmpty);
      return;
    }
    if (!_isCompressed) {
      _showMessage(l10n.schoolHtmlImportCompressFirst);
      return;
    }
    final sanitizedContent = html;

    setState(() => _isSubmitting = true);
    try {
      final result = await _api.importCurrentPageWithRawResponse(
        SchoolImportPagePayload(
          url: widget.initialUrl,
          title: widget.initialTitle,
          html: sanitizedContent,
          locale: localeCode,
        ),
      );
      if (!mounted) {
        return;
      }
      await _showApiResponseDialog(result.rawBody);
      if (!mounted) {
        return;
      }
      final response = result.response;
      final periodTimeSets = provider.periodTimeSets;
      final selectedPeriodTimeSetId =
          provider.activePeriodTimeSetOrNull?.id ??
          (periodTimeSets.isEmpty ? '' : periodTimeSets.first.id);
      final importResult = await showModalBottomSheet<SchoolWebImportResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SchoolWebImportResultSheet(
          response: response,
          canReplaceCurrent: canReplaceCurrent,
          periodTimeSets: periodTimeSets,
          initialPeriodTimeSetId: selectedPeriodTimeSetId,
          provider: provider,
        ),
      );
      if (importResult == null || !mounted) {
        return;
      }
      await provider.importSchoolWebResponseWithPeriodTimeSet(
        importResult.response,
        mode: importResult.mode,
        periodTimeSetId: importResult.selectedPeriodTimeSetId,
      );
      if (!mounted) {
        return;
      }
      _showMessage(l10n.schoolWebImportSuccess);
      Navigator.of(context).pop();
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      await _showApiResponseDialog(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.importFailedCheckContent);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showApiResponseDialog(String message) async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('API Response'),
          content: SingleChildScrollView(child: SelectableText(message)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
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
}
