import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'services/announcement_service.dart';

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
import 'view_models/home_view_model.dart';

import 'providers/theme_notifier.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'doswall_service_channel',
    'Layanan Presensi',
    description: 'Layanan presensi sedang aktif berjalan.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'doswall_service_channel',
    'Layanan Presensi',
    channelDescription: 'Layanan presensi sedang aktif berjalan.',
    ongoing: true,
    priority: Priority.high,
  );

  await flutterLocalNotificationsPlugin.show(
    888,
    'Presensi Aktif',
    'Layanan sedang berjalan di latar belakang.',
    const NotificationDetails(android: androidNotificationDetails),
  );

  service.on('stop').listen((event) {
    flutterLocalNotificationsPlugin.cancel(888);
  });
  service.on('stop_service').listen((event) {
    service.stopSelf();
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await initializeService();

  final themeNotifier = await ThemeNotifier.create();
  runApp(MyApp(themeNotifier: themeNotifier));
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  const MyApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ChangePasswordViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementsViewModel(service: AnnouncementService())),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, currentTheme, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Doswall',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: currentTheme.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('id', 'ID'),
            ],
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
      ),
    );
  }
}