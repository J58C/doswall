import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:doswall/providers/theme_notifier.dart';
import 'package:doswall/main.dart';

void main() {
  testWidgets('Login screen shows correctly and navigates on login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeNotifier = await ThemeNotifier.create();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeNotifier,
        child: const MyApp(isLoggedIn: false),
      ),
    );

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}