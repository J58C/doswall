import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/profile_screen.dart';

import 'view_models/login_view_model.dart';
import 'view_models/forgot_password_view_model.dart';
import 'view_models/change_password_view_model.dart';
import 'view_models/announcements_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/splash_view_model.dart';

import 'services/announcement_service.dart';
import 'services/api_client.dart';
import 'providers/theme_notifier.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(minutes: 1), (timer) {
    debugPrint('Service Presensi Aktif...');
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'doswall_service',
      initialNotificationTitle: 'Doswall',
      initialNotificationContent: 'Layanan presensi sedang aktif.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) async => true,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeService();

  final themeNotifier = await ThemeNotifier.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeNotifier),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementsViewModel(service: AnnouncementService()),),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Doswall',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeNotifier.themeMode,
          initialRoute: '/',

          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/forgot': (context) => const ForgotPasswordScreen(),
            '/announcements': (context) => const AnnouncementsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
          },
        );
      },
    );
  }
}