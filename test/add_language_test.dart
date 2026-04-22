import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/add_language.dart';

void main() {
  test('protects and restores ARB placeholders', () {
    const source = 'Week {week} · {count} courses';

    final protected = protectArbPlaceholders(source);

    expect(protected.text, 'Week __ARB_PH_0__ · __ARB_PH_1__ courses');
    expect(
      restoreArbPlaceholders('第__ARB_PH_0__周 · __ARB_PH_1__门课程', protected),
      '第{week}周 · {count}门课程',
    );
  });

  test('throws when translated text loses placeholder tokens', () {
    final protected = protectArbPlaceholders('Week {week}');

    expect(
      () => restoreArbPlaceholders('第周', protected),
      throwsA(isA<FormatException>()),
    );
  });

  test('builds translated ARB while preserving metadata', () async {
    final arb = await buildTranslatedArbFromTemplate(
      <String, dynamic>{
        '@@locale': 'en',
        'title': 'Settings',
        'weekLabel': 'Week {week}',
        '@weekLabel': {
          'placeholders': {
            'week': {'type': 'int'},
          },
        },
      },
      'zh',
      translator:
          (
            text, {
            required String fromLocaleCode,
            required String toLocaleCode,
          }) async {
            if (text == 'Settings') {
              return '设置';
            }
            if (text == 'Week __ARB_PH_0__') {
              return '第__ARB_PH_0__周';
            }
            return text;
          },
    );

    expect(arb['@@locale'], 'zh');
    expect(arb['title'], '设置');
    expect(arb['@title'], <String, dynamic>{});
    expect(arb['weekLabel'], '第{week}周');
    expect(
      jsonEncode(arb['@weekLabel']),
      jsonEncode({
        'placeholders': {
          'week': {'type': 'int'},
        },
      }),
    );
  });

  test('merges localized names with manual overrides', () async {
    final names = await buildEffectiveLocalizedNames(
      locale: 'nl',
      nativeName: 'Nederlands',
      englishName: 'Dutch',
      supportedUiLocales: const ['de', 'en', 'zh'],
      manualLocalizedNames: const {'zh': '荷兰文'},
      translator:
          (
            text, {
            required String fromLocaleCode,
            required String toLocaleCode,
          }) async {
            return switch (toLocaleCode) {
              'de' => 'Niederländisch',
              'zh' => '荷兰语',
              _ => text,
            };
          },
    );

    expect(names['en'], 'Dutch');
    expect(names['nl'], 'Nederlands');
    expect(names['de'], 'Niederländisch');
    expect(names['zh'], '荷兰文');
  });

  test('inserts metadata entry in sorted order', () {
    const source = '''import 'package:flutter/widgets.dart';

const _supportedLanguageMetadata = <String, AppLanguageMetadata>{
  'en': AppLanguageMetadata(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    localizedNames: {
      'en': 'English',
    },
  ),
  'zh': AppLanguageMetadata(
    code: 'zh',
    nativeName: '中文',
    englishName: 'Chinese',
    localizedNames: {
      'zh': '中文',
    },
  ),
};
''';

    final updated = insertLanguageMetadata(
      source: source,
      entry: buildMetadataEntry(
        const AddLanguageConfig(
          locale: 'nl',
          nativeName: 'Nederlands',
          englishName: 'Dutch',
          localizedNames: {'en': 'Dutch', 'nl': 'Nederlands', 'zh': '荷兰语'},
        ),
      ),
    );

    expect(
      updated.indexOf("'en': AppLanguageMetadata("),
      lessThan(updated.indexOf("'nl': AppLanguageMetadata(")),
    );
    expect(
      updated.indexOf("'nl': AppLanguageMetadata("),
      lessThan(updated.indexOf("'zh': AppLanguageMetadata(")),
    );
  });

  test('extracts Baidu API error messages', () {
    expect(
      extractBaiduErrorMessage({
        'error_code': '54001',
        'error_msg': 'Invalid Sign',
      }),
      'Baidu Translate failed (54001): Invalid Sign',
    );
    expect(extractBaiduErrorMessage({'ok': true}), isNull);
  });
}
