import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/school_import_models.dart';
import 'school_import_content_sanitizer.dart';

class SchoolWebImportPageService {
  const SchoolWebImportPageService();

  static const extractImportHtmlScript = '''
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

  Future<SchoolImportSourcePayload> extractSource(
    InAppWebViewController controller, {
    required String fallbackUrl,
    required String fallbackTitle,
  }) async {
    final html = await controller.evaluateJavascript(source: extractImportHtmlScript);
    final currentUrl = (await controller.getUrl())?.toString() ?? fallbackUrl;
    final title = await _safeGetTitle(controller, fallbackTitle: fallbackTitle);
    final normalizedContent = SchoolImportContentSanitizer.sanitize(
      _normalizeJavaScriptResult(html).trim(),
    );
    if (normalizedContent.isEmpty) {
      throw const FormatException('Import content is empty.');
    }
    return SchoolImportSourcePayload(
      url: currentUrl,
      title: title,
      content: normalizedContent,
    );
  }

  Future<String> _safeGetTitle(
    InAppWebViewController controller, {
    required String fallbackTitle,
  }) async {
    try {
      return await controller.getTitle() ?? fallbackTitle;
    } catch (_) {
      return fallbackTitle;
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
