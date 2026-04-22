import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

typedef LocaleTranslator =
    Future<String> Function(
      String text, {
      required String fromLocaleCode,
      required String toLocaleCode,
    });

const _jsonEncoder = JsonEncoder.withIndent('  ');
const _baiduTranslateEndpoint =
    'https://fanyi-api.baidu.com/api/trans/vip/translate';
const _baiduLanguageCodes = <String, String>{
  'ar': 'ara',
  'bg': 'bul',
  'cs': 'cs',
  'da': 'dan',
  'de': 'de',
  'el': 'el',
  'en': 'en',
  'es': 'spa',
  'et': 'est',
  'fi': 'fin',
  'fr': 'fra',
  'he': 'heb',
  'hi': 'hi',
  'hu': 'hu',
  'id': 'id',
  'it': 'it',
  'ja': 'jp',
  'ko': 'kor',
  'lt': 'lit',
  'lv': 'lav',
  'ms': 'may',
  'nl': 'nl',
  'no': 'nor',
  'pl': 'pl',
  'pt': 'pt',
  'ro': 'rom',
  'ru': 'ru',
  'sk': 'sk',
  'sl': 'slo',
  'sr': 'srp',
  'sv': 'swe',
  'th': 'th',
  'tr': 'tr',
  'uk': 'ukr',
  'vi': 'vie',
  'zh': 'zh',
};

void main(List<String> args) async {
  final config = parseArgs(args);
  final root = Directory.current;
  final l10nDir = Directory(joinPath(root.path, 'lib', 'l10n'));
  final templateFile = File(joinPath(l10nDir.path, 'app_en.arb'));
  final appLocaleFile = File(joinPath(l10nDir.path, 'app_locale.dart'));

  if (!templateFile.existsSync()) {
    stderr.writeln('Template ARB not found: ${templateFile.path}');
    exitCode = 1;
    return;
  }
  if (!appLocaleFile.existsSync()) {
    stderr.writeln('Locale metadata file not found: ${appLocaleFile.path}');
    exitCode = 1;
    return;
  }

  final normalizedLocaleCode = normalizeLanguageOnlyLocale(config.locale);
  if (normalizedLocaleCode != config.locale) {
    stderr.writeln(
      'Only language-only locale codes are supported in this tool for now. '
      'Use values like en, fr, ko, nl.',
    );
    exitCode = 1;
    return;
  }

  final targetArbFile = File(
    joinPath(l10nDir.path, 'app_$normalizedLocaleCode.arb'),
  );
  if (targetArbFile.existsSync()) {
    stderr.writeln('Target ARB already exists: ${targetArbFile.path}');
    exitCode = 1;
    return;
  }

  final appLocaleSource = appLocaleFile.readAsStringSync();
  final existingSupportedUiLocales = extractSupportedUiLocales(appLocaleSource);
  if (existingSupportedUiLocales.contains(normalizedLocaleCode)) {
    stderr.writeln(
      'Locale $normalizedLocaleCode already exists in app_locale.dart metadata.',
    );
    exitCode = 1;
    return;
  }

  final credentials = readBaiduCredentialsFromEnvironment();
  final client = BaiduTranslateClient(
    appId: credentials.appId,
    secret: credentials.secret,
  );

  final generatedLocalizationsFile = File(
    joinPath(l10nDir.path, 'app_localizations_$normalizedLocaleCode.dart'),
  );

  var appLocaleWritten = false;
  var arbWritten = false;

  try {
    stdout.writeln('Translating ARB strings for $normalizedLocaleCode...');

    final effectiveLocalizedNames = await buildEffectiveLocalizedNames(
      locale: normalizedLocaleCode,
      nativeName: config.nativeName,
      englishName: config.englishName,
      supportedUiLocales: existingSupportedUiLocales,
      manualLocalizedNames: config.localizedNames,
      translator: client.translateUsingLocaleCodes,
    );
    final effectiveConfig = AddLanguageConfig(
      locale: normalizedLocaleCode,
      nativeName: config.nativeName,
      englishName: config.englishName,
      localizedNames: effectiveLocalizedNames,
    );

    final templateData =
        jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;
    final newArb = await buildTranslatedArbFromTemplate(
      templateData,
      effectiveConfig.locale,
      translator: client.translateUsingLocaleCodes,
    );
    final updatedAppLocaleSource = insertLanguageMetadata(
      source: appLocaleSource,
      entry: buildMetadataEntry(effectiveConfig),
    );

    targetArbFile.writeAsStringSync('${_jsonEncoder.convert(newArb)}\n');
    arbWritten = true;

    appLocaleFile.writeAsStringSync(updatedAppLocaleSource);
    appLocaleWritten = true;

    final genL10nResult = await Process.run(
      'flutter',
      const ['gen-l10n'],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(genL10nResult.stdout);
    stderr.write(genL10nResult.stderr);
    if (genL10nResult.exitCode != 0) {
      throw const FormatException('flutter gen-l10n failed.');
    }

    if (!generatedLocalizationsFile.existsSync()) {
      throw FormatException(
        'Expected generated localization file was not created: '
        '${generatedLocalizationsFile.path}',
      );
    }

    final generatedAppLocalizations = File(
      joinPath(l10nDir.path, 'app_localizations.dart'),
    ).readAsStringSync();
    if (!generatedAppLocalizations.contains(
      "Locale('$normalizedLocaleCode')",
    )) {
      throw FormatException(
        'Generated supportedLocales does not contain $normalizedLocaleCode.',
      );
    }

    stdout.writeln(
      'Added language $normalizedLocaleCode with translated ARB content.',
    );
    stdout.writeln('ARB: ${targetArbFile.path}');
    stdout.writeln('Metadata updated: ${appLocaleFile.path}');
    stdout.writeln('Generated: ${generatedLocalizationsFile.path}');
    stdout.writeln(
      'Next: review the translations, then run flutter analyze && flutter test.',
    );
  } on FormatException catch (error) {
    await rollbackAddLanguage(
      root: root,
      appLocaleFile: appLocaleFile,
      originalAppLocaleSource: appLocaleSource,
      targetArbFile: targetArbFile,
      generatedLocalizationsFile: generatedLocalizationsFile,
      appLocaleWritten: appLocaleWritten,
      arbWritten: arbWritten,
    );
    stderr.writeln(error.message);
    exitCode = 1;
  } catch (error) {
    await rollbackAddLanguage(
      root: root,
      appLocaleFile: appLocaleFile,
      originalAppLocaleSource: appLocaleSource,
      targetArbFile: targetArbFile,
      generatedLocalizationsFile: generatedLocalizationsFile,
      appLocaleWritten: appLocaleWritten,
      arbWritten: arbWritten,
    );
    stderr.writeln('Failed to add language: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}

class AddLanguageConfig {
  const AddLanguageConfig({
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.localizedNames,
  });

  final String locale;
  final String nativeName;
  final String englishName;
  final Map<String, String> localizedNames;
}

class BaiduTranslateCredentials {
  const BaiduTranslateCredentials({required this.appId, required this.secret});

  final String appId;
  final String secret;
}

class ProtectedTranslationText {
  const ProtectedTranslationText({required this.text, required this.tokens});

  final String text;
  final Map<String, String> tokens;
}

class BaiduTranslateClient {
  BaiduTranslateClient({
    required this.appId,
    required this.secret,
    http.Client? client,
    this.endpoint = _baiduTranslateEndpoint,
  }) : _client = client;

  final String appId;
  final String secret;
  final http.Client? _client;
  final String endpoint;

  Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || from == to) {
      return text;
    }

    final client = _client ?? http.Client();
    final ownsClient = _client == null;
    try {
      FormatException? lastEmptyTranslationError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final salt = DateTime.now().microsecondsSinceEpoch.toString();
          final sign = md5
              .convert(utf8.encode('$appId$text$salt$secret'))
              .toString();
          final uri = Uri.parse(endpoint).replace(
            queryParameters: {
              'q': text,
              'from': from,
              'to': to,
              'appid': appId,
              'salt': salt,
              'sign': sign,
            },
          );
          final response = await client.get(
            uri,
            headers: const {'Accept': 'application/json'},
          );
          final rawBody = utf8.decode(response.bodyBytes);
          final decoded = tryDecodeJson(rawBody);
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw FormatException(
              extractBaiduErrorMessage(decoded) ??
                  'Baidu Translate request failed (${response.statusCode}).',
            );
          }
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException(
              'Baidu Translate response format is invalid.',
            );
          }
          final errorMessage = extractBaiduErrorMessage(decoded);
          if (errorMessage != null) {
            throw FormatException(errorMessage);
          }
          final transResult = decoded['trans_result'];
          if (transResult is! List || transResult.isEmpty) {
            throw const FormatException(
              'Baidu Translate response format is invalid.',
            );
          }
          final translatedParts = transResult
              .map((item) => item is Map ? item['dst']?.toString() ?? '' : '')
              .where((item) => item.isNotEmpty)
              .toList();
          if (translatedParts.isEmpty) {
            throw const FormatException(
              'Baidu Translate returned empty translated text.',
            );
          }
          return translatedParts.join('\n');
        } on FormatException catch (error) {
          if (error.message !=
                  'Baidu Translate returned empty translated text.' ||
              attempt == 2) {
            rethrow;
          }
          lastEmptyTranslationError = error;
        }
      }
      throw lastEmptyTranslationError ??
          const FormatException(
            'Baidu Translate returned empty translated text.',
          );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Unable to connect to Baidu Translate.\n\n$error');
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  Future<String> translateUsingLocaleCodes(
    String text, {
    required String fromLocaleCode,
    required String toLocaleCode,
  }) {
    return translate(
      text,
      from: baiduLanguageCodeForLocale(fromLocaleCode),
      to: baiduLanguageCodeForLocale(toLocaleCode),
    );
  }

  void close() {
    _client?.close();
  }
}

AddLanguageConfig parseArgs(List<String> args) {
  String? locale;
  String? nativeName;
  String? englishName;
  final localizedNames = <String, String>{};

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (!arg.startsWith('--')) {
      fail('Unexpected argument: $arg');
    }
    if (index + 1 >= args.length) {
      fail('Missing value for argument: $arg');
    }
    final value = args[++index].trim();
    if (arg == '--locale') {
      locale = value;
      continue;
    }
    if (arg == '--native-name') {
      nativeName = value;
      continue;
    }
    if (arg == '--english-name') {
      englishName = value;
      continue;
    }
    if (arg.startsWith('--name.')) {
      final localeCode = arg.substring('--name.'.length).trim();
      if (localeCode.isEmpty) {
        fail('Invalid localized name argument: $arg');
      }
      localizedNames[localeCode] = value;
      continue;
    }
    fail('Unknown argument: $arg');
  }

  if (locale == null || locale.isEmpty) {
    fail('Missing required argument: --locale');
  }
  if (nativeName == null || nativeName.isEmpty) {
    fail('Missing required argument: --native-name');
  }
  if (englishName == null || englishName.isEmpty) {
    fail('Missing required argument: --english-name');
  }

  return AddLanguageConfig(
    locale: locale,
    nativeName: nativeName,
    englishName: englishName,
    localizedNames: localizedNames,
  );
}

Never fail(String message) {
  stderr.writeln(message);
  stderr.writeln(
    'Usage: dart run tool/add_language.dart '
    '--locale <code> --native-name <text> --english-name <text> '
    '[--name.zh <text> --name.en <text> ...]\n'
    'Requires BAIDU_TRANSLATE_APP_ID and BAIDU_TRANSLATE_SECRET environment variables.',
  );
  exit(1);
}

String normalizeLanguageOnlyLocale(String localeCode) {
  final raw = localeCode.trim().replaceAll('_', '-');
  final parts = raw.split('-').where((part) => part.isNotEmpty).toList();
  if (parts.length != 1) {
    return raw;
  }
  return parts.single.toLowerCase();
}

String baiduLanguageCodeForLocale(String localeCode) {
  final normalizedCode = normalizeLanguageOnlyLocale(localeCode);
  final baiduCode = _baiduLanguageCodes[normalizedCode];
  if (baiduCode == null) {
    throw FormatException(
      'Locale $localeCode is not supported by Baidu Translate in this tool yet.',
    );
  }
  return baiduCode;
}

BaiduTranslateCredentials readBaiduCredentialsFromEnvironment() {
  final appId = Platform.environment['BAIDU_TRANSLATE_APP_ID']?.trim() ?? '';
  final secret = Platform.environment['BAIDU_TRANSLATE_SECRET']?.trim() ?? '';
  if (appId.isEmpty || secret.isEmpty) {
    throw const FormatException(
      'Missing Baidu Translate credentials. Set BAIDU_TRANSLATE_APP_ID and '
      'BAIDU_TRANSLATE_SECRET before running this tool.',
    );
  }
  return BaiduTranslateCredentials(appId: appId, secret: secret);
}

Future<Map<String, dynamic>> buildTranslatedArbFromTemplate(
  Map<String, dynamic> template,
  String locale, {
  required LocaleTranslator translator,
}) async {
  final result = <String, dynamic>{};
  for (final entry in template.entries) {
    if (entry.key == '@@locale') {
      result[entry.key] = locale;
      continue;
    }
    if (entry.key.startsWith('@')) {
      result[entry.key] = entry.value;
      continue;
    }

    final value = entry.value;
    if (value is String && shouldTranslateArbValue(value)) {
      final protected = protectArbPlaceholders(value);
      final translated = await translator(
        protected.text,
        fromLocaleCode: 'en',
        toLocaleCode: locale,
      );
      result[entry.key] = restoreArbPlaceholders(translated, protected);
    } else {
      result[entry.key] = value;
    }

    final metaKey = '@${entry.key}';
    if (!template.containsKey(metaKey)) {
      result[metaKey] = <String, dynamic>{};
    }
  }
  return result;
}

bool shouldTranslateArbValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
    return false;
  }
  if (RegExp(r'^[\w.-]+\.[A-Za-z]{2,}([/\w\-.?=&%#]*)?$').hasMatch(trimmed)) {
    return false;
  }
  return RegExp(r'[A-Za-z]').hasMatch(trimmed);
}

ProtectedTranslationText protectArbPlaceholders(String value) {
  final tokens = <String, String>{};
  final protectedText = value.replaceAllMapped(RegExp(r'\{[^{}]+\}'), (match) {
    final token = '__ARB_PH_${tokens.length}__';
    tokens[token] = match.group(0)!;
    return token;
  });
  return ProtectedTranslationText(text: protectedText, tokens: tokens);
}

String restoreArbPlaceholders(
  String translatedText,
  ProtectedTranslationText protectedText,
) {
  var restored = translatedText;
  for (final entry in protectedText.tokens.entries) {
    final tokenPattern = RegExp(RegExp.escape(entry.key));
    final tokenMatches = tokenPattern.allMatches(restored).length;
    if (tokenMatches != 1) {
      throw FormatException(
        'Translated text did not preserve placeholder token ${entry.key}.',
      );
    }
    restored = restored.replaceFirst(entry.key, entry.value);
  }
  final leftoverToken = RegExp(r'__ARB_PH_\d+__').firstMatch(restored);
  if (leftoverToken != null) {
    throw const FormatException(
      'Translated text still contains unresolved placeholder tokens.',
    );
  }
  return restored;
}

Future<Map<String, String>> buildEffectiveLocalizedNames({
  required String locale,
  required String nativeName,
  required String englishName,
  required Iterable<String> supportedUiLocales,
  required Map<String, String> manualLocalizedNames,
  required LocaleTranslator translator,
}) async {
  final fallbackName = englishName.trim();
  final result = <String, String>{'en': englishName, locale: nativeName};

  for (final uiLocale in supportedUiLocales) {
    if (uiLocale == 'en' || uiLocale == locale) {
      continue;
    }
    final manualValue = manualLocalizedNames[uiLocale]?.trim();
    if (manualValue != null && manualValue.isNotEmpty) {
      result[uiLocale] = manualValue;
      continue;
    }
    try {
      final translated = await translator(
        englishName,
        fromLocaleCode: 'en',
        toLocaleCode: uiLocale,
      );
      final normalizedTranslated = translated.trim();
      result[uiLocale] = normalizedTranslated.isEmpty
          ? fallbackName
          : normalizedTranslated;
    } on FormatException {
      result[uiLocale] = fallbackName;
    }
  }

  for (final entry in manualLocalizedNames.entries) {
    final value = entry.value.trim();
    if (value.isNotEmpty) {
      result[entry.key] = value;
    }
  }

  return Map.fromEntries(
    result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

List<String> extractSupportedUiLocales(String source) {
  final match = RegExp(
    r"const _supportedLanguageMetadata = <String, AppLanguageMetadata>\{([\s\S]*?)\n\};",
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    throw StateError('Could not locate _supportedLanguageMetadata block.');
  }
  final block = match.group(1)!;
  final matches = RegExp(
    r"^  '([a-zA-Z\-]+)': AppLanguageMetadata\(",
    multiLine: true,
  ).allMatches(block);
  return matches.map((item) => item.group(1)!).toList()..sort();
}

String buildMetadataEntry(AddLanguageConfig config) {
  final buffer = StringBuffer();
  buffer.writeln("  '${config.locale}': AppLanguageMetadata(");
  buffer.writeln("    code: '${config.locale}',");
  buffer.writeln("    nativeName: '${escapeSingleQuoted(config.nativeName)}',");
  buffer.writeln(
    "    englishName: '${escapeSingleQuoted(config.englishName)}',",
  );
  buffer.writeln('    localizedNames: {');

  final sortedNames = Map.fromEntries(
    config.localizedNames.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
  for (final entry in sortedNames.entries) {
    buffer.writeln(
      "      '${entry.key}': '${escapeSingleQuoted(entry.value)}',",
    );
  }
  buffer.writeln('    },');
  buffer.writeln('  ),');
  return buffer.toString();
}

String insertLanguageMetadata({required String source, required String entry}) {
  final match = RegExp(
    r"const _supportedLanguageMetadata = <String, AppLanguageMetadata>\{([\s\S]*?)\n\};",
    multiLine: true,
  ).firstMatch(source);
  if (match == null) {
    throw StateError('Could not locate _supportedLanguageMetadata block.');
  }

  final block = match.group(1)!;
  final entries = RegExp(
    r"^  '[a-zA-Z\-]+': AppLanguageMetadata\([\s\S]*?^  \),$",
    multiLine: true,
  ).allMatches(block).map((item) => item.group(0)!).toList();
  entries.add(entry.trimRight());
  entries.sort((a, b) {
    final aCode = RegExp(
      r"^  '([a-zA-Z\-]+)'",
      multiLine: true,
    ).firstMatch(a)!.group(1)!;
    final bCode = RegExp(
      r"^  '([a-zA-Z\-]+)'",
      multiLine: true,
    ).firstMatch(b)!.group(1)!;
    return aCode.compareTo(bCode);
  });

  final replacement =
      'const _supportedLanguageMetadata = <String, AppLanguageMetadata>{\n'
      '${entries.join('\n')}\n};';
  return source.replaceRange(match.start, match.end, replacement);
}

String escapeSingleQuoted(String value) {
  return value.replaceAll('\\', r'\\').replaceAll("'", r"\'");
}

Object? tryDecodeJson(String rawBody) {
  try {
    return jsonDecode(rawBody);
  } catch (_) {
    return null;
  }
}

String? extractBaiduErrorMessage(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }
  final errorCode = decoded['error_code']?.toString().trim();
  final errorMessage = decoded['error_msg']?.toString().trim();
  if (errorCode == null || errorCode.isEmpty) {
    return null;
  }
  if (errorMessage == null || errorMessage.isEmpty) {
    return 'Baidu Translate failed ($errorCode).';
  }
  return 'Baidu Translate failed ($errorCode): $errorMessage';
}

Future<void> rollbackAddLanguage({
  required Directory root,
  required File appLocaleFile,
  required String originalAppLocaleSource,
  required File targetArbFile,
  required File generatedLocalizationsFile,
  required bool appLocaleWritten,
  required bool arbWritten,
}) async {
  if (!appLocaleWritten &&
      !arbWritten &&
      !generatedLocalizationsFile.existsSync()) {
    return;
  }

  stderr.writeln('Rolling back partial changes...');
  if (appLocaleWritten) {
    appLocaleFile.writeAsStringSync(originalAppLocaleSource);
  }
  if (arbWritten && targetArbFile.existsSync()) {
    targetArbFile.deleteSync();
  }
  if (generatedLocalizationsFile.existsSync()) {
    generatedLocalizationsFile.deleteSync();
  }

  final genL10nResult = await Process.run(
    'flutter',
    const ['gen-l10n'],
    workingDirectory: root.path,
    runInShell: true,
  );
  if (genL10nResult.exitCode != 0) {
    stderr.writeln('Rollback warning: flutter gen-l10n failed.');
    stderr.write(genL10nResult.stderr);
  }
}

String joinPath(String part1, String part2, [String? part3, String? part4]) {
  final separator = Platform.pathSeparator;
  final parts = [part1, part2, part3, part4].whereType<String>();
  return parts.join(separator);
}
