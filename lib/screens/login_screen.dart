import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/view_state.dart';
import '../view_models/login_view_model.dart';

import '../providers/theme_notifier.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _emailController.addListener(() => context.read<LoginViewModel>().resetState());
    _passwordController.addListener(() => context.read<LoginViewModel>().resetState());
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<LoginViewModel>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      onSuccess: () {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildArtisticBackground(context, isDark),
          Positioned(
            top: 40, right: 16,
            child: IconButton(
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildGlassmorphismCard(context, loginViewModel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismCard(BuildContext context, LoginViewModel loginViewModel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withAlpha((255 * (isDark ? 0.2 : 0.4)).round()),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.onSurface.withAlpha((255 * 0.1).round())),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildEmailField(context),
                const SizedBox(height: 16),
                _buildPasswordField(context, loginViewModel),
                const SizedBox(height: 12),
                _buildForgotPassword(context, loginViewModel),
                const SizedBox(height: 24),
                _buildErrorMessage(loginViewModel),
                const SizedBox(height: 8),
                _buildLoginButton(context, loginViewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context, LoginViewModel loginViewModel) {
    final bool isLoading = loginViewModel.state == ViewState.loading;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: isLoading ? null : (_) => _login(),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (value) { if (value == null || value.isEmpty) { return 'Password tidak boleh kosong'; } return null; },
    );
  }

  Widget _buildForgotPassword(BuildContext context, LoginViewModel loginViewModel) {
    final bool isLoading = loginViewModel.state == ViewState.loading;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: isLoading ? null : () => Navigator.pushNamed(context, '/forgot'),
        child: const Text('Lupa Password?'),
      ),
    );
  }

  Widget _buildErrorMessage(LoginViewModel loginViewModel) {
    final bool isError = loginViewModel.state == ViewState.error;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isError ? 1.0 : 0.0,
      child: !isError
          ? const SizedBox(height: 48)
          : Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(loginViewModel.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginViewModel loginViewModel) {
    final bool isLoading = loginViewModel.state == ViewState.loading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
        ),
        onPressed: isLoading ? null : _login,
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Login'),
      ),
    );
  }

  Widget _buildArtisticBackground(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Stack(children: [ Positioned(top: -100, left: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withAlpha((255 * (isDark ? 0.2 : 0.3)).round())))), Positioned(bottom: -150, right: -150, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: secondary.withAlpha((255 * (isDark ? 0.25 : 0.35)).round()))))]);
  }
  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(children: [ Icon(Icons.school_outlined, size: 48, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 16), Text('Selamat Datang', style: textTheme.headlineSmall, textAlign: TextAlign.center), const SizedBox(height: 4), Text('Masuk untuk melanjutkan ke sistem presensi.', style: textTheme.bodyMedium, textAlign: TextAlign.center)]);
  }
  Widget _buildEmailField(BuildContext context) {
    return TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (value) { if (value == null || value.isEmpty) { return 'Email tidak boleh kosong'; } final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"); if (!emailRegex.hasMatch(value)) { return 'Format email tidak valid'; } return null; });
  }
}