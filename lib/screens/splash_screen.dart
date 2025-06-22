import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/splash_view_model.dart';
import '../services/auth_service.dart';
import '../models/background_shape.dart';

import '../widgets/artistic_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _loadingFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await context.read<SplashViewModel>().initializeApp(
      onComplete: (authResult) {
        if (!mounted) return;

        if (authResult == AuthResult.authenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final List<BackgroundShape> splashScreenPattern = [
      BackgroundShape(
        top: -100,
        left: -100,
        width: 300,
        height: 300,
        color: primary.withAlpha(isDark ? 40 : 60),
      ),
      BackgroundShape(
        bottom: -150,
        right: -150,
        width: 400,
        height: 400,
        color: secondary.withAlpha(isDark ? 45 : 65),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          ArtisticBackground(shapes: splashScreenPattern),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 80, color: theme.colorScheme.primary),
                        const SizedBox(height: 20),
                        Text('Doswall', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _loadingFadeAnimation,
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3.0,
                        color: theme.colorScheme.primary.withAlpha(200),
                      ),
                      const SizedBox(height: 16),
                      Text('Memuat sesi...', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}