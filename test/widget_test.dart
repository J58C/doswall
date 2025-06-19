import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doswall/providers/theme_notifier.dart';
import 'package:doswall/main.dart';
import 'package:doswall/screens/login_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen and navigates to LoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final themeNotifier = await ThemeNotifier.create();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeNotifier,
        child: MyApp(themeNotifier: themeNotifier),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat sesi...'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
