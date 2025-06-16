import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_notifier.dart';
import '../services/password_service.dart';
import '../models/password_response.dart';
import '../theme/custom_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _passwordChangedSuccessfully = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final PasswordResponse result = await PasswordService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _passwordChangedSuccessfully = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal mengubah password.'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak dapat terhubung ke server.'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = theme.brightness == Brightness.dark;
    Color appBarColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    Color onAppBarColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Ganti Password', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
        backgroundColor: appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(50),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            color: onAppBarColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildArtisticBackground(context, isDark),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: _passwordChangedSuccessfully
                    ? _buildSuccessView(context)
                    : _buildFormView(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisticBackground(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withAlpha(isDark ? 30 : 50),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tertiary.withAlpha(isDark ? 35 : 55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      key: const ValueKey('form_view'),
      opacity: _fadeAnimation,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.password_rounded, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Perbarui Password Anda', style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Pastikan password baru Anda kuat dan mudah diingat.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _buildPasswordField(
              context: context,
              controller: _oldPasswordController,
              labelText: 'Password Lama',
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              context: context,
              controller: _newPasswordController,
              labelText: 'Password Baru',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password baru tidak boleh kosong';
                if (value.length < 8) return 'Password minimal 8 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              context: context,
              controller: _confirmPasswordController,
              labelText: 'Konfirmasi Password Baru',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                if (value != _newPasswordController.text) return 'Password tidak cocok';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ganti Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) return '$labelText tidak boleh kosong';
        return null;
      },
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final successColor = Theme.of(context).extension<CustomColors>()?.success ?? Colors.green;

    return FadeTransition(
      key: const ValueKey('success_view'),
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline, size: 70, color: successColor),
          const SizedBox(height: 24),
          Text('Password Berhasil Diubah!', style: textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Anda akan diarahkan kembali.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}