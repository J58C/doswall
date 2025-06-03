import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../services/user_storage.dart';
import '../providers/theme_notifier.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _passwordFieldKey = GlobalKey<FormFieldState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;
  String? _loginError;

  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
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
    setState(() {
      _loading = true;
      _loginError = null;
    });

    final AuthResponse result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success && result.userData != null) {
      final user = result.userData!;
      await UserStorage.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      setState(() {
        _loginError = result.message ?? 'Email atau password salah atau akun tidak aktif.';
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final Brightness currentPlatformBrightness = MediaQuery.platformBrightnessOf(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system && currentPlatformBrightness == Brightness.dark);

    IconData themeIcon = isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    String themeTooltip = isEffectivelyDark ? 'Ubah ke Mode Terang' : 'Ubah ke Mode Gelap';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _animController,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_person_outlined,
                            size: 70,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Selamat Datang',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan masuk untuk melanjutkan',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withAlpha(180),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            key: _emailFieldKey,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant),
                            ),
                            onChanged: (value) {
                              if (_loginError != null) {
                                setState(() => _loginError = null);
                                _emailFieldKey.currentState?.validate();
                                _passwordFieldKey.currentState?.validate();
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                              final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                              if (!emailRegex.hasMatch(value)) return 'Format email tidak valid';
                              if (_loginError != null && (_loginError!.toLowerCase().contains('email') || _loginError!.toLowerCase().contains('salah'))) {
                                return _loginError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: _passwordFieldKey,
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: _loading ? null : (_) => _login(),
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            onChanged: (value) {
                              if (_loginError != null) {
                                setState(() => _loginError = null);
                                _emailFieldKey.currentState?.validate();
                                _passwordFieldKey.currentState?.validate();
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                              if (_loginError != null && (_loginError!.toLowerCase().contains('password') || _loginError!.toLowerCase().contains('salah'))) {
                                final errorToDisplay = _loginError;
                                return errorToDisplay;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : () => Navigator.pushNamed(context, '/forgot'),
                              child: const Text('Lupa Password?'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? colorScheme.onPrimary,
                                  ),
                                ),
                              )
                                  : const Text('Login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: Icon(themeIcon),
                color: colorScheme.onSurface,
                tooltip: themeTooltip,
                onPressed: () {
                  themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}