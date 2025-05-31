import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Pastikan path ini benar
import '../services/user_storage.dart'; // Pastikan path ini benar

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

    // Logika animasi Anda tetap dipertahankan
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

  // Logika _login() Anda tetap sama persis
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

    // Pastikan widget masih mounted sebelum memanggil setState
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      final user = result['data'];
      await UserStorage.saveUser(user);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      setState(() {
        _loginError = result['message'] as String? ?? 'Email atau password salah';
      });
      // Re-validate untuk menampilkan error dari server pada field
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Menggunakan warna surface dari tema
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_person_outlined, // Ikon yang lebih sesuai dengan Material 3
                        size: 80,
                        color: colorScheme.primary, // Menggunakan warna primary dari tema
                      ),
                      const SizedBox(height: 24),
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
                          color: colorScheme.onSurface.withAlpha((180)), // Opacity ~70%
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration( // Gaya akan diambil dari inputDecorationTheme
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant),
                          // border, borderRadius, dll. akan dari tema
                        ),
                        onChanged: (value) { // Logika onChanged Anda tetap
                          if (_loginError != null) {
                            setState(() {
                              _loginError = null;
                            });
                            // Memicu validasi ulang untuk membersihkan error dari server jika pengguna mulai mengetik
                            _emailFieldKey.currentState?.validate();
                            _passwordFieldKey.currentState?.validate();
                          }
                        },
                        validator: (value) { // Logika validator Anda tetap
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                          if (!emailRegex.hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          // Hanya tampilkan _loginError jika relevan dengan field ini
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
                        onFieldSubmitted: _loading ? null : (_) => _login(), // Menjalankan _login saat submit
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration( // Gaya akan diambil dari inputDecorationTheme
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          // border, borderRadius, dll. akan dari tema
                        ),
                        onChanged: (value) { // Logika onChanged Anda tetap
                          if (_loginError != null) {
                            setState(() {
                              _loginError = null;
                            });
                            // Memicu validasi ulang untuk membersihkan error dari server jika pengguna mulai mengetik
                            _emailFieldKey.currentState?.validate();
                            _passwordFieldKey.currentState?.validate();
                          }
                        },
                        validator: (value) { // Logika validator Anda tetap
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          // Hanya tampilkan _loginError jika relevan dengan field ini
                          if (_loginError != null && (_loginError!.toLowerCase().contains('password') || _loginError!.toLowerCase().contains('salah'))) {
                            // Simpan error untuk ditampilkan, lalu null-kan agar tidak menempel terus
                            final errorToDisplay = _loginError;
                            // _loginError = null; // Pertimbangkan apakah ini perlu di-reset di sini atau setelah submit
                            return errorToDisplay;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : () {
                            Navigator.pushNamed(context, '/forgot');
                          },
                          // Gaya TextButton akan diambil dari tema
                          child: const Text('Lupa Password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          // Style (backgroundColor, shape, textStyle) akan diambil dari elevatedButtonTheme
                          child: _loading
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              // Warna akan diambil dari foregroundColor ElevatedButton
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}) ??
                                    colorScheme.onPrimary, // Fallback jika tidak ada di tema tombol
                              ),
                            ),
                          )
                              : const Text('Login'), // TextStyle akan dari tema tombol
                        ),
                      ),
                      // Bagian Lupa Password di bawah tombol Login dihapus karena sudah dipindah ke atas
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