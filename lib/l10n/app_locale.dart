import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

const defaultLocaleCode = 'zh';
const _defaultNonChineseLocaleCode = 'en';

@immutable
class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.locale,
    required this.label,
  });

  final String code;
  final Locale locale;
  final String label;
}

String localeCodeFromLocale(Locale locale) {
  final parts = <String>[locale.languageCode.toLowerCase()];
  final scriptCode = locale.scriptCode;
  final countryCode = locale.countryCode;
  if (scriptCode != null && scriptCode.isNotEmpty) {
    parts.add(_normalizeScriptCode(scriptCode));
  }
  if (countryCode != null && countryCode.isNotEmpty) {
    parts.add(countryCode.toUpperCase());
  }
  return parts.join('-');
}

String normalizeLocaleCode(String? localeCode) {
  final raw = localeCode?.trim();
  if (raw == null || raw.isEmpty) {
    return defaultLocaleCode;
  }
  final exactMatch = _findSupportedLocale(
    _parseLocaleCode(raw),
    allowLanguageFallback: false,
  );
  if (exactMatch != null) {
    return localeCodeFromLocale(exactMatch);
  }
  final languageMatch = _findSupportedLocale(
    _parseLocaleCode(raw),
    allowLanguageFallback: true,
  );
  if (languageMatch != null) {
    return localeCodeFromLocale(languageMatch);
  }
  return defaultLocaleCode;
}

Locale appLocaleFromCode(String localeCode) {
  final locale = _findSupportedLocale(
    _parseLocaleCode(localeCode),
    allowLanguageFallback: true,
  );
  return locale ?? _defaultAppLocale;
}

String resolveFirstLaunchLocaleCode(Locale? locale) {
  if (locale == null) {
    return _englishOrDefaultLocaleCode;
  }
  if (_isTraditionalChinese(locale) && _supportsLanguageCode('zh')) {
    return normalizeLocaleCode('zh');
  }
  return _englishOrDefaultLocaleCode;
}

List<AppLanguageOption> supportedLanguageOptions(AppLocalizations l10n) {
  final options = AppLocalizations.supportedLocales
      .map(
        (locale) => AppLanguageOption(
          code: localeCodeFromLocale(locale),
          locale: locale,
          label: languageLabelForLocaleCode(
            l10n,
            localeCodeFromLocale(locale),
          ),
        ),
      )
      .toList();
  options.sort((a, b) {
    final priorityCompare = _languageSortPriority(
      a.code,
    ).compareTo(_languageSortPriority(b.code));
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.label.compareTo(b.label);
  });
  return List.unmodifiable(options);
}

String languageLabelForLocaleCode(AppLocalizations l10n, String localeCode) {
  switch (normalizeLocaleCode(localeCode)) {
    case 'en':
      return l10n.languageEnglish;
    case 'zh':
      return l10n.languageChinese;
    default:
      return localeCode;
  }
}

int _languageSortPriority(String localeCode) {
  return switch (normalizeLocaleCode(localeCode)) {
    'zh' => 0,
    'en' => 1,
    _ => 2,
  };
}

bool _supportsLanguageCode(String languageCode) {
  return AppLocalizations.supportedLocales.any(
    (locale) => locale.languageCode.toLowerCase() == languageCode,
  );
}

Locale? _findSupportedLocale(
  Locale locale, {
  required bool allowLanguageFallback,
}) {
  final requestedCode = localeCodeFromLocale(locale);
  for (final supportedLocale in AppLocalizations.supportedLocales) {
    if (localeCodeFromLocale(supportedLocale) == requestedCode) {
      return supportedLocale;
    }
  }
  if (!allowLanguageFallback) {
    return null;
  }
  final requestedLanguageCode = locale.languageCode.toLowerCase();
  for (final supportedLocale in AppLocalizations.supportedLocales) {
    if (supportedLocale.languageCode.toLowerCase() == requestedLanguageCode) {
      return supportedLocale;
    }
  }
  return null;
}

Locale _parseLocaleCode(String localeCode) {
  final segments = localeCode
      .trim()
      .replaceAll('_', '-')
      .split('-')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return _defaultAppLocale;
  }
  final languageCode = segments.first.toLowerCase();
  String? scriptCode;
  String? countryCode;
  if (segments.length >= 2) {
    final second = segments[1];
    if (second.length == 4) {
      scriptCode = _normalizeScriptCode(second);
      if (segments.length >= 3) {
        countryCode = segments[2].toUpperCase();
      }
    } else {
      countryCode = second.toUpperCase();
    }
  }
  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}

String _normalizeScriptCode(String scriptCode) {
  if (scriptCode.isEmpty) {
    return scriptCode;
  }
  return '${scriptCode[0].toUpperCase()}${scriptCode.substring(1).toLowerCase()}';
}

bool _isTraditionalChinese(Locale locale) {
  final scriptCode = locale.scriptCode?.toLowerCase();
  final countryCode = locale.countryCode?.toUpperCase();
  return locale.languageCode.toLowerCase() == 'zh' &&
      (scriptCode == 'hant' ||
          countryCode == 'TW' ||
          countryCode == 'HK' ||
          countryCode == 'MO');
}

String get _englishOrDefaultLocaleCode {
  return _supportsLanguageCode(_defaultNonChineseLocaleCode)
      ? normalizeLocaleCode(_defaultNonChineseLocaleCode)
      : defaultLocaleCode;
}

Locale get _defaultAppLocale {
  return _findSupportedLocale(
        _parseLocaleCode(defaultLocaleCode),
        allowLanguageFallback: true,
      ) ??
      AppLocalizations.supportedLocales.first;
}
