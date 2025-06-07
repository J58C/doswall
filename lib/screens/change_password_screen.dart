import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_notifier.dart';
import '../services/change_password_service.dart';
import '../models/change_password_response.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldPasswordObscure = true;
  bool _newPasswordObscure = true;
  bool _confirmPasswordObscure = true;
  bool _loading = false;

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final ChangePasswordResponse result = await ChangePasswordService.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? (result.success ? 'Password berhasil diubah!' : 'Gagal mengubah password.')),
        backgroundColor: result.success ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.success) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    bool isCurrentlyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system && theme.brightness == Brightness.dark);
    IconData themeIcon = isCurrentlyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    String themeTooltip = isCurrentlyDark ? 'Mode Terang' : 'Mode Gelap';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Password'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: themeTooltip,
            onPressed: () {
              themeNotifier.toggleTheme(isCurrentlyDark ? Brightness.dark : Brightness.light);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(Icons.lock_person_outlined, size: 60, color: colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Atur Ulang Password Anda',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan password baru Anda kuat dan mudah diingat.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: _oldPasswordObscure,
                    decoration: InputDecoration(
                      labelText: 'Password Lama',
                      prefixIcon: Icon(Icons.password_outlined, color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(_oldPasswordObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant),
                        onPressed: () => setState(() => _oldPasswordObscure = !_oldPasswordObscure),
                      ),
                    ),
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password lama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _newPasswordObscure,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(_newPasswordObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant),
                        onPressed: () => setState(() => _newPasswordObscure = !_newPasswordObscure),
                      ),
                    ),
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _confirmPasswordObscure,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      prefixIcon: Icon(Icons.lock_reset_outlined, color: colorScheme.onSurfaceVariant),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: colorScheme.onSurfaceVariant),
                        onPressed: () => setState(() => _confirmPasswordObscure = !_confirmPasswordObscure),
                      ),
                    ),
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _submitChangePassword,
                    icon: _loading ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2.0), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) : const Icon(Icons.save_outlined),
                    label: Text(_loading ? 'Menyimpan...' : 'Simpan Password Baru'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
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