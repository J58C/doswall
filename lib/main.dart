import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/announcements_screen.dart';
import 'services/user_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final user = await UserStorage.getUser();
  final isLoggedIn = user['token'].isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doswall',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/forgot': (_) => ForgotPasswordScreen(),
        '/announcements': (_) => AnnouncementsScreen(),
      },
    );
  }
}