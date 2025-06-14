import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Beri sedikit jeda agar animasi atau logo terlihat (opsional)
    await Future.delayed(const Duration(seconds: 1));

    // Pengecekan 'mounted' penting untuk menghindari error jika user
    // keluar dari screen sebelum navigasi terjadi.
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final authResult = await AuthService.checkAuthentication();

    if (authResult == AuthResult.authenticated) {
      navigator.pushReplacementNamed('/home');
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Anda bisa ganti dengan logo aplikasi Anda
            Icon(Icons.shield_moon_outlined, size: 80),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat sesi...'),
          ],
        ),
      ),
    );
  }
}