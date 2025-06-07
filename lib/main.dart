import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_notifier.dart';
import 'theme/app_theme.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/change_password_screen.dart';
import 'services/user_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final user = await UserStorage.getUser();
  final isLoggedIn = user['token'] != null && user['token'].toString().isNotEmpty;
  final themeNotifier = await ThemeNotifier.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Doswall',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeNotifier.themeMode,
          initialRoute: isLoggedIn ? '/home' : '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const HomeScreen(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/announcements': (_) => const AnnouncementsScreen(),
            '/change-password': (_) => const ChangePasswordScreen(),
          },
        );
      },
    );
  }
}