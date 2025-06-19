// test/widget_test.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doswall/providers/theme_notifier.dart';
import 'package:doswall/screens/splash_screen.dart';
import 'package:doswall/screens/login_screen.dart';
import 'package:doswall/screens/home_screen.dart';
import 'package:doswall/view_models/login_view_model.dart';
import 'package:doswall/view_models/forgot_password_view_model.dart';
import 'package:doswall/view_models/change_password_view_model.dart';
import 'package:doswall/view_models/announcements_view_model.dart';
import 'package:doswall/view_models/profile_view_model.dart';
import 'package:doswall/view_models/splash_view_model.dart';
import 'package:doswall/services/announcement_service.dart';

Widget createTestAppWidget({required Widget child, required ThemeNotifier themeNotifier}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeNotifier),
      ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
      ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
      ChangeNotifierProvider(create: (_) => AnnouncementsViewModel(service: AnnouncementService())),
      ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ChangeNotifierProvider(create: (_) => SplashViewModel()),
    ],
    child: Consumer<ThemeNotifier>(
      builder: (context, currentTheme, _) {
        return MaterialApp(
          themeMode: currentTheme.themeMode,
          home: child,
        );
      },
    ),
  );
}

void main() {
  group('App Initialization Flow', () {

    testWidgets('App starts with SplashScreen and navigates to LoginScreen if not logged in', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final themeNotifier = await ThemeNotifier.create();

      await tester.pumpWidget(
        createTestAppWidget(
          child: const SplashScreen(),
          themeNotifier: themeNotifier,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat sesi...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Selamat Datang'), findsOneWidget);
    });

    testWidgets('App navigates to HomeScreen if user is already logged in', (WidgetTester tester) async {

      final mockUser = {'token': 'dummy-token', 'name': 'User Uji', 'email': 'uji@test.com', 'role': 'user'};
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(mockUser)
      });

      final themeNotifier = await ThemeNotifier.create();

      await tester.pumpWidget(
        createTestAppWidget(
          child: const SplashScreen(),
          themeNotifier: themeNotifier,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Selamat Datang,'), findsOneWidget);
    });
  });

  group('Login Screen Interaction', () {
    testWidgets('Shows error message on failed login', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final themeNotifier = await ThemeNotifier.create();

      await tester.pumpWidget(
        createTestAppWidget(
          child: const LoginScreen(),
          themeNotifier: themeNotifier,
        ),
      );

      await tester.enterText(find.byKey(const Key('login_email_field')), 'salah@email.com');
      await tester.enterText(find.byKey(const Key('login_password_field')), 'passwordsalah');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}