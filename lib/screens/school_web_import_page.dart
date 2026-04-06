import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/school_site_models.dart';
import '../screens/school_html_import_page.dart';
import '../services/school_site_service.dart';

class SchoolWebImportPage extends StatefulWidget {
  const SchoolWebImportPage({super.key, required this.site});

  final SchoolSite site;

  @override
  State<SchoolWebImportPage> createState() => _SchoolWebImportPageState();
}

class _SchoolWebImportPageState extends State<SchoolWebImportPage> {
  final SchoolSiteService _siteService = const SchoolSiteService();

  WebViewController? _controller;
  bool _isLoadingPage = false;
  bool _isParsing = false;
  bool _isLoadingSchools = true;
  String _currentUrl = '';
  String _currentTitle = '';
  List<SchoolSite> _sites = const [];
  SchoolSite? _selectedSite;
  String? _schoolLoadError;

  bool get _isConfigured => AppConfig.hasSchoolImportApiBaseUrl;
  bool get _supportsWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSite?.name ?? widget.site.name),
        actions: [
          IconButton(
            onPressed: _controller == null || _isParsing ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _controller == null || _isLoadingPage || _isParsing
                ? null
                : _importCurrentPage,
            icon: _isParsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: l10n.schoolWebImportImportCurrentPage,
          ),
        ],
      ),
      body: !_isConfigured
          ? _buildMessage(l10n.schoolWebImportConfigMissing)
          : !_supportsWebView
          ? _buildMessage(l10n.schoolWebImportUnsupportedPlatform)
          : _schoolLoadError != null
          ? _buildMessage(_schoolLoadError!)
          : _sites.isEmpty || _selectedSite == null
          ? _buildMessage(l10n.schoolWebImportNoSchools)
          : Column(
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      _isLoadingSchools
                          ? l10n.schoolWebImportLoadingPage
                          : _isParsing
                          ? l10n.schoolWebImportParsing
                          : _isLoadingPage
                          ? l10n.schoolWebImportLoadingPage
                          : l10n.schoolWebImportOpenPageHint,
                    ),
                  ),
                ),
                Expanded(
                  child: _controller == null || _isLoadingSchools
                      ? const Center(child: CircularProgressIndicator())
                      : WebViewWidget(controller: _controller!),
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

  Future<void> _loadSchools() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final sites = await _siteService.loadSites();
      if (!mounted) {
        return;
      }
      final selected = sites.where((item) => item.loginUrl == widget.site.loginUrl).firstOrNull;
      setState(() {
        _sites = sites;
        _selectedSite = selected ?? widget.site;
        _isLoadingSchools = false;
      });
      await _ensureController();
      await _openSelectedSchool();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingSchools = false;
        _schoolLoadError = l10n.schoolWebImportSchoolLoadFailed;
      });
    }
  }

  Future<void> _ensureController() async {
    if (_controller != null || !_supportsWebView) {
      return;
    }
    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoadingPage = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) async {
            final title = await _safeGetTitle(controller);
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoadingPage = false;
              _currentUrl = url;
              _currentTitle = title;
            });
          },
        ),
      );
    setState(() {
      _controller = controller;
      _isLoadingPage = true;
    });
  }

  Future<void> _openSelectedSchool() async {
    final site = _selectedSite;
    final controller = _controller;
    if (site == null || controller == null) {
      return;
    }
    await controller.loadRequest(Uri.parse(site.loginUrl));
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.reload();
  }

  Future<void> _importCurrentPage() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final selectedSite = _selectedSite;
    if (controller == null || selectedSite == null) {
      return;
    }
    setState(() => _isParsing = true);
    try {
      final html = await controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );
      final title = await _safeGetTitle(controller);
      final currentUrl = await controller.currentUrl() ?? _currentUrl;
      final normalizedHtml = _normalizeJavaScriptResult(html).trim();
      if (normalizedHtml.isEmpty) {
        throw FormatException(l10n.schoolWebImportEmptyPage);
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SchoolHtmlImportPage(
            initialContent: normalizedHtml,
            initialUrl: currentUrl,
            initialTitle: title,
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.importFailedCheckContent)));
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  Future<String> _safeGetTitle(WebViewController controller) async {
    try {
      return await controller.getTitle() ?? _currentTitle;
    } catch (_) {
      return _currentTitle;
    }
  }

  String _normalizeJavaScriptResult(Object value) {
    if (value is String) {
      return value;
    }
    final text = value.toString();
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
