import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/timetable_provider.dart';
import 'screens/home_screen.dart';

const _appIconLicense =
    '''Classmate 的应用启动图标及相关平台图标资源基于 Google Material Icons / Material Symbols 修改。

Copyright Google LLC
Licensed under the Apache License, Version 2.0

The icon assets distributed with this app were modified from the original source materials.

Apache License 2.0:
https://www.apache.org/licenses/LICENSE-2.0''';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  final provider = TimetableProvider();
  unawaited(provider.load());
  runApp(MyApp(provider: provider));
}

void _registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks([
      'App icon assets',
    ], _appIconLicense);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.provider});

  final TimetableProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimetableProvider>.value(
      value: provider,
      child: Consumer<TimetableProvider>(
        builder: (context, timetableProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            locale: Locale(timetableProvider.localeCode),
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6750A4),
              ),
              cardTheme: const CardThemeData(margin: EdgeInsets.zero),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
