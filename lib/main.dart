import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/timetable_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  final provider = TimetableProvider();
  unawaited(provider.load());
  runApp(MyApp(provider: provider));
}

void _registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    final notice = await rootBundle.loadString('NOTICE');
    yield LicenseEntryWithLineBreaks([
      'App icon assets',
    ], notice);
  });
}

ThemeMode _themeModeFromValue(String value) {
  switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}




ThemeData _buildTheme({
  required Color seedColor,
  required Brightness brightness,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
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
            themeMode: _themeModeFromValue(timetableProvider.themeMode),
            theme: _buildTheme(
              seedColor: Color(timetableProvider.themeSeedColorValue),
              brightness: Brightness.light,
            ),
            darkTheme: _buildTheme(
              seedColor: Color(timetableProvider.themeSeedColorValue),
              brightness: Brightness.dark,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
