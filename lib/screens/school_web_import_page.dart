import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../models/school_site_models.dart';
import '../screens/school_html_import_page.dart';
import '../services/school_import_content_sanitizer.dart';
import '../services/school_site_service.dart';

class SchoolWebImportPage extends StatefulWidget {
  const SchoolWebImportPage({super.key, required this.site});

  final SchoolSite site;

  @override
  State<SchoolWebImportPage> createState() => _SchoolWebImportPageState();
}

class _SchoolWebImportPageState extends State<SchoolWebImportPage> {
  static const _extractImportHtmlScript = '''
(() => {
  const root = document.documentElement;
  if (!root) {
    return '';
  }
  const cloned = root.cloneNode(true);
  cloned.querySelectorAll('script,style,noscript,svg,canvas,iframe,template').forEach((node) => node.remove());
  return cloned.outerHTML;
})()
''';

  final SchoolSiteService _siteService = const SchoolSiteService();

  InAppWebViewController? _controller;
  bool _isLoadingPage = false;
  bool _isParsing = false;
  bool _isLoadingSchools = true;
  bool _canGoBack = false;
  String _currentUrl = '';
  String _currentTitle = '';
  List<SchoolSite> _sites = const [];
  SchoolSite? _selectedSite;
  String? _schoolLoadError;

  bool get _isConfigured => AppConfig.hasSchoolImportApiBaseUrl;
  bool get _supportsWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.windows);

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
          TextButton(
            onPressed: _canGoBack && !_isParsing ? _goBackInWebView : null,
            child: Text(l10n.schoolWebImportGoBack),
          ),
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
                  child: _isLoadingSchools
                      ? const Center(child: CircularProgressIndicator())
                      : InAppWebView(
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            javaScriptCanOpenWindowsAutomatically: true,
                          ),
                          onWebViewCreated: (controller) async {
                            _controller = controller;
                            await _updateCanGoBackState(controller);
                            if (_selectedSite != null) {
                              await _openSelectedSchool();
                            }
                          },
                          onLoadStart: (controller, url) async {
                            await _updateCanGoBackState(controller);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _isLoadingPage = true;
                              _currentUrl = url?.toString() ?? '';
                            });
                          },
                          onLoadStop: (controller, url) async {
                            final title = await _safeGetTitle(controller);
                            final canGoBack = await controller.canGoBack();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _isLoadingPage = false;
                              _canGoBack = canGoBack;
                              _currentUrl = url?.toString() ?? '';
                              _currentTitle = title;
                            });
                          },
                          onUpdateVisitedHistory: (controller, url, _) async {
                            await _updateCanGoBackState(controller);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _currentUrl = url?.toString() ?? _currentUrl;
                            });
                          },
                        ),
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
    if (mounted) {
      setState(() {
        _isLoadingPage = true;
      });
    }
  }

  Future<void> _openSelectedSchool() async {
    final site = _selectedSite;
    final controller = _controller;
    if (site == null || controller == null) {
      return;
    }
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri(site.loginUrl)),
    );
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.reload();
  }

  Future<void> _goBackInWebView() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (!await controller.canGoBack()) {
      if (mounted) {
        setState(() => _canGoBack = false);
      }
      return;
    }
    await controller.goBack();
    await _updateCanGoBackState(controller);
  }

  Future<void> _updateCanGoBackState(InAppWebViewController controller) async {
    final canGoBack = await controller.canGoBack();
    if (!mounted || _canGoBack == canGoBack) {
      return;
    }
    setState(() => _canGoBack = canGoBack);
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
      final html = await controller.evaluateJavascript(
        source: _extractImportHtmlScript,
      );
      final title = await _safeGetTitle(controller);
      final currentUrl = (await controller.getUrl())?.toString() ?? _currentUrl;
      final normalizedHtml = SchoolImportContentSanitizer.sanitize(
        _normalizeJavaScriptResult(html).trim(),
      );
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
            showReturnToWebPageButton: true,
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

  Future<String> _safeGetTitle(InAppWebViewController controller) async {
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
