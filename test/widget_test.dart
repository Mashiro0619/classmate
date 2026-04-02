import 'package:classmate/main.dart';
import 'package:classmate/providers/timetable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows timetable home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = TimetableProvider();
    await provider.load();

    await tester.pumpWidget(MyApp(provider: provider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('添加课程'), findsWidgets);
    expect(find.textContaining('第 '), findsWidgets);
    expect(find.text('2026 春季学期'), findsOneWidget);
  });
}
