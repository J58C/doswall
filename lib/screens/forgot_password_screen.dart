import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_notifier.dart';
import '../services/forgot_password_service.dart';
import '../models/forgot_password_response.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ForgotPasswordResponse result = await ForgotPasswordService.requestPasswordReset(
      _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(result.success ? 'Email Terkirim' : 'Gagal'),
        content: Text(result.message ?? (result.success ? 'Silakan periksa email Anda.' : 'Terjadi kesalahan.')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (result.success) {
                // Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Lupa Password'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: themeTooltip,
            onPressed: () {
              themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const ClampingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    size: 70,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reset Password Anda',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masukkan alamat email yang terdaftar. Kami akan mengirimkan tautan untuk mengatur ulang password Anda.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: _loading ? null : (_) => _sendResetEmail(),
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Email Terdaftar',
                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                      final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
                      if (!emailRegex.hasMatch(value)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendResetEmail,
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
                          : const Text('Kirim Email Reset'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}