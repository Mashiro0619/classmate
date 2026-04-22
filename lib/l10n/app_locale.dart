import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

const defaultLocaleCode = 'zh';

@immutable
class AppLanguageMetadata {
  const AppLanguageMetadata({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.localizedNames,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final Map<String, String> localizedNames;

  String localizedNameFor(String uiLocaleCode) {
    return localizedNames[uiLocaleCode] ??
        localizedNames[defaultLocaleCode] ??
        englishName;
  }
}

@immutable
class AppLanguageOption {
  const AppLanguageOption({
    required this.code,
    required this.locale,
    required this.nativeName,
    required this.localizedName,
    required this.englishName,
  });

  final String code;
  final Locale locale;
  final String nativeName;
  final String localizedName;
  final String englishName;

  String get label => localizedName;
}

const _supportedLanguageMetadata = <String, AppLanguageMetadata>{
  'de': AppLanguageMetadata(
    code: 'de',
    nativeName: 'Deutsch',
    englishName: 'German',
    localizedNames: {
      'de': 'Deutsch',
      'en': 'German',
      'es': 'Alemán',
      'fr': 'Allemand',
      'it': 'Tedesco',
      'ja': 'ドイツ語',
      'ko': '독일어',
      'pt': 'Alemão',
      'ru': 'Немецкий',
      'zh': '德语',
    },
  ),
  'en': AppLanguageMetadata(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    localizedNames: {
      'de': 'Englisch',
      'en': 'English',
      'es': 'Inglés',
      'fr': 'Anglais',
      'it': 'Inglese',
      'ja': '英語',
      'ko': '영어',
      'pt': 'Inglês',
      'ru': 'Английский',
      'zh': '英语',
    },
  ),
  'es': AppLanguageMetadata(
    code: 'es',
    nativeName: 'Español',
    englishName: 'Spanish',
    localizedNames: {
      'de': 'Spanisch',
      'en': 'Spanish',
      'es': 'Español',
      'fr': 'Espagnol',
      'it': 'Spagnolo',
      'ja': 'スペイン語',
      'ko': '스페인어',
      'pt': 'Espanhol',
      'ru': 'Испанский',
      'zh': '西班牙语',
    },
  ),
  'fr': AppLanguageMetadata(
    code: 'fr',
    nativeName: 'Français',
    englishName: 'French',
    localizedNames: {
      'de': 'Französisch',
      'en': 'French',
      'es': 'Francés',
      'fr': 'Français',
      'it': 'Francese',
      'ja': 'フランス語',
      'ko': '프랑스어',
      'pt': 'Francês',
      'ru': 'Французский',
      'zh': '法语',
    },
  ),
  'it': AppLanguageMetadata(
    code: 'it',
    nativeName: 'Italiano',
    englishName: 'Italian',
    localizedNames: {
      'de': 'Italienisch',
      'en': 'Italian',
      'es': 'Italiano',
      'fr': 'Italien',
      'it': 'Italiano',
      'ja': 'イタリア語',
      'ko': '이탈리아어',
      'pt': 'Italiano',
      'ru': 'Итальянский',
      'zh': '意大利语',
    },
  ),
  'ja': AppLanguageMetadata(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    localizedNames: {
      'de': 'Japanisch',
      'en': 'Japanese',
      'es': 'Japonés',
      'fr': 'Japonais',
      'it': 'Giapponese',
      'ja': '日本語',
      'ko': '일본어',
      'pt': 'Japonês',
      'ru': 'Японский',
      'zh': '日语',
    },
  ),
  'ko': AppLanguageMetadata(
    code: 'ko',
    nativeName: '한국어',
    englishName: 'Korean',
    localizedNames: {
      'de': 'Koreanisch',
      'en': 'Korean',
      'es': 'Coreano',
      'fr': 'Coréen',
      'it': 'Coreano',
      'ja': '韓国語',
      'ko': '한국어',
      'pt': 'Coreano',
      'ru': 'Корейский',
      'zh': '韩语',
    },
  ),
  'pt': AppLanguageMetadata(
    code: 'pt',
    nativeName: 'Português',
    englishName: 'Portuguese',
    localizedNames: {
      'de': 'Portugiesisch',
      'en': 'Portuguese',
      'es': 'Portugués',
      'fr': 'Portugais',
      'it': 'Portoghese',
      'ja': 'ポルトガル語',
      'ko': '포르투갈어',
      'pt': 'Português',
      'ru': 'Португальский',
      'zh': '葡萄牙语',
    },
  ),
  'ru': AppLanguageMetadata(
    code: 'ru',
    nativeName: 'Русский',
    englishName: 'Russian',
    localizedNames: {
      'de': 'Russisch',
      'en': 'Russian',
      'es': 'Ruso',
      'fr': 'Russe',
      'it': 'Russo',
      'ja': 'ロシア語',
      'ko': '러시아어',
      'pt': 'Russo',
      'ru': 'Русский',
      'zh': '俄语',
    },
  ),
  'zh': AppLanguageMetadata(
    code: 'zh',
    nativeName: '中文',
    englishName: 'Chinese',
    localizedNames: {
      'de': 'Chinesisch',
      'en': 'Chinese',
      'es': 'Chino',
      'fr': 'Chinois',
      'it': 'Cinese',
      'ja': '中国語',
      'ko': '중국어',
      'pt': 'Chinês',
      'ru': 'Китайский',
      'zh': '中文',
    },
  ),
};

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
    return localeCodeFromLocale(_defaultAppLocale);
  }
  final locale = _findSupportedLocale(
    _parseLocaleCode(raw),
    allowLanguageFallback: true,
  );
  return locale == null
      ? localeCodeFromLocale(_defaultAppLocale)
      : localeCodeFromLocale(locale);
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
    return localeCodeFromLocale(_defaultAppLocale);
  }
  final exactLocale = _findSupportedLocale(
    locale,
    allowLanguageFallback: false,
  );
  if (exactLocale != null) {
    return localeCodeFromLocale(exactLocale);
  }
  final languageLocale = _findSupportedLocale(
    locale,
    allowLanguageFallback: true,
  );
  if (languageLocale != null) {
    return localeCodeFromLocale(languageLocale);
  }
  return localeCodeFromLocale(_defaultAppLocale);
}

List<AppLanguageOption> supportedLanguageOptions(AppLocalizations l10n) {
  final uiLocaleCode = normalizeLocaleCode(l10n.localeName);
  final options = AppLocalizations.supportedLocales.map((locale) {
    final code = localeCodeFromLocale(locale);
    final metadata = languageMetadataForLocaleCode(code);
    return AppLanguageOption(
      code: code,
      locale: locale,
      nativeName: metadata.nativeName,
      localizedName: metadata.localizedNameFor(uiLocaleCode),
      englishName: metadata.englishName,
    );
  }).toList();
  options.sort((a, b) {
    final priorityCompare = _languageSortPriority(a.code).compareTo(
      _languageSortPriority(b.code),
    );
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.localizedName.compareTo(b.localizedName);
  });
  return List.unmodifiable(options);
}

AppLanguageMetadata languageMetadataForLocaleCode(String localeCode) {
  final normalizedCode = normalizeLocaleCode(localeCode);
  return _supportedLanguageMetadata[normalizedCode] ??
      AppLanguageMetadata(
        code: normalizedCode,
        nativeName: normalizedCode,
        englishName: normalizedCode,
        localizedNames: {defaultLocaleCode: normalizedCode},
      );
}

String languageLabelForLocaleCode(
  String localeCode, {
  AppLocalizations? l10n,
}) {
  final metadata = languageMetadataForLocaleCode(localeCode);
  if (l10n == null) {
    return metadata.nativeName;
  }
  return metadata.localizedNameFor(normalizeLocaleCode(l10n.localeName));
}

bool isSupportedLocaleCode(String localeCode) {
  final normalizedCode = normalizeLocaleCode(localeCode);
  return AppLocalizations.supportedLocales.any(
    (locale) => localeCodeFromLocale(locale) == normalizedCode,
  );
}

int _languageSortPriority(String localeCode) {
  return normalizeLocaleCode(localeCode) == normalizeLocaleCode(defaultLocaleCode)
      ? 0
      : 1;
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

Locale get _defaultAppLocale {
  return _findSupportedLocale(
        _parseLocaleCode(defaultLocaleCode),
        allowLanguageFallback: true,
      ) ??
      AppLocalizations.supportedLocales.first;
}
