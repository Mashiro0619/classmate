class SchoolImportContentSanitizer {
  const SchoolImportContentSanitizer._();

  static const int maxContentLength = 120000;

  static final RegExp _attributePattern = RegExp(
    r'''\s(?:style|class|id|onclick|ondblclick|onchange|oninput|onload|onerror|onfocus|onblur|onmousedown|onmouseup|onmousemove|onmouseenter|onmouseleave|onmouseover|onmouseout|onkeydown|onkeyup|data-[\w:-]+|aria-[\w-]+)\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)''',
    caseSensitive: false,
  );

  static String sanitize(String source) {
    var cleaned = source;
    cleaned = cleaned.replaceAll(
      RegExp(r'<script\b[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<style\b[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<noscript\b[^>]*>[\s\S]*?<\/noscript>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<svg\b[^>]*>[\s\S]*?<\/svg>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<canvas\b[^>]*>[\s\S]*?<\/canvas>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<iframe\b[^>]*>[\s\S]*?<\/iframe>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<template\b[^>]*>[\s\S]*?<\/template>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    cleaned = cleaned.replaceAll(_attributePattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\r\n]+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[\t\x0B\f ]{2,}'), ' ');
    cleaned = cleaned.trim();
    if (cleaned.length <= maxContentLength) {
      return cleaned;
    }
    return cleaned.substring(0, maxContentLength);
  }
}
