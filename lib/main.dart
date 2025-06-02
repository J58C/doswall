import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_notifier.dart'; // Impor ThemeNotifier Anda
import 'theme/app_theme.dart';        // Impor fungsi tema
// Impor untuk CustomColors tidak lagi diperlukan di sini jika hanya digunakan di app_theme.dart
// Jika Anda mengakses CustomColors.of(context) di MyApp atau main, maka impor theme/custom_colors.dart

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/announcements_screen.dart';
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
          theme: buildLightTheme(), // Menggunakan fungsi dari app_theme.dart
          darkTheme: buildDarkTheme(), // Menggunakan fungsi dari app_theme.dart
          themeMode: themeNotifier.themeMode,
          initialRoute: isLoggedIn ? '/home' : '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const HomeScreen(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/announcements': (_) => const AnnouncementsScreen(),
          },
        );
      },
    );
  }
}