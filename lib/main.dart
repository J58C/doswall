import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/theme_notifier.dart';
import 'theme/app_theme.dart';
import 'models/announcement.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/add_announcement_screen.dart';
import 'screens/edit_announcement_screen.dart';
import 'services/user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

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
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/home':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case '/forgot':
                return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
              case '/announcements':
                return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());
              case '/add-announcement':
                return MaterialPageRoute(builder: (_) => const AddAnnouncementScreen());
              case '/edit-announcement':
                if (settings.arguments is Announcement) {
                  final announcement = settings.arguments as Announcement;
                  return MaterialPageRoute(builder: (_) => EditAnnouncementScreen(announcement: announcement));
                }
                return MaterialPageRoute(builder: (_) => const AnnouncementsScreen());
              case '/change-password':
                return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
              default:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
          },
        );
      },
    );
  }
}