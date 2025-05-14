import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_storage.dart';

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
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
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

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (result['success']) {
      final user = result['data'];
      await UserStorage.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      setState(() {
        _loginError = result['message'] ?? 'Email atau password salah';
      });

      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _animController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 80, color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Selamat Datang',
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk untuk melanjutkan',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        onChanged: (_) {
                          setState(() {
                            _loginError = null;
                          });
                          _emailFieldKey.currentState?.validate();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Email tidak valid';
                          }
                          if (_loginError != null) {
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
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        onChanged: (_) {
                          setState(() {
                            _loginError = null;
                          });
                          _passwordFieldKey.currentState?.validate();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (_loginError != null) {
                            return _loginError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot');
                        },
                        child: const Text('Lupa Password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}