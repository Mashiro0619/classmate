import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/timetable_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = TimetableProvider();
  unawaited(provider.load());
  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.provider});

  final TimetableProvider provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimetableProvider>.value(
      value: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Classmate',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
          cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
