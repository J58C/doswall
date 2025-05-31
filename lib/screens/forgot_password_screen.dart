import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Logika _sendResetEmail() Anda tetap sama persis
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Menutup keyboard
    setState(() => _loading = true);

    final res = await http.post(
      Uri.parse('https://doegus.sigmaskibidi.my.id/appkey/password/mailpw'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'appkey': 'DOEGUSAPPACCESSCORS', // Pastikan appkey ini aman
      }),
    );

    if (!mounted) return; // Pengecekan mounted setelah async gap
    setState(() => _loading = false);

    final success = res.statusCode == 200;
    String dialogMessage = '';

    if (success) {
      try {
        // Mencoba parsing respons JSON jika sukses
        final responseBody = jsonDecode(res.body);
        dialogMessage = responseBody['message'] as String? ?? 'Link reset password telah dikirim ke email kamu.';
      } catch (e) {
        // Fallback jika respons bukan JSON atau tidak ada 'message'
        dialogMessage = 'Link reset password telah dikirim ke email kamu.';
      }
    } else {
      try {
        // Mencoba parsing respons JSON jika gagal
        final responseBody = jsonDecode(res.body);
        dialogMessage = responseBody['message'] as String? ?? 'Gagal mengirim email. Pastikan email benar atau coba lagi nanti.';
      } catch (e) {
        // Fallback jika respons bukan JSON atau tidak ada 'message'
        dialogMessage = 'Gagal mengirim email. Status: ${res.statusCode}. Pastikan email benar atau coba lagi nanti.';
      }
    }


    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        // Menggunakan gaya dialog dari tema
        title: Text(success ? 'Email Terkirim' : 'Gagal'),
        content: Text(dialogMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Gunakan dialogContext
              if (success) {
                // Pertimbangkan untuk kembali ke halaman login atau halaman sebelumnya
                // Navigator.pop(context); // Kembali dari ForgotPasswordScreen
              }
            },
            child: const Text('OK'), // Gaya TextButton akan dari tema
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // AppBar akan mengambil gaya dari appBarTheme
        title: const Text('Lupa Password'),
        // Pertimbangkan untuk menambahkan tombol kembali jika ini bukan rute awal
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const ClampingScrollPhysics(), // Bisa juga BouncingScrollPhysics
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Agar konten tidak memenuhi seluruh tinggi
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset_outlined, // Ikon yang lebih sesuai dengan Material 3
                    size: 80,
                    color: colorScheme.primary, // Menggunakan warna primary dari tema
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Password Anda', // Teks yang lebih jelas
                    style: textTheme.headlineMedium?.copyWith( // Sedikit lebih besar dari headlineSmall
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground, // Warna teks di atas background utama
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Masukkan alamat email yang terdaftar. Kami akan mengirimkan tautan untuk mengatur ulang password Anda.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground.withAlpha(180), // Opacity ~70%
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done, // Langsung done karena hanya satu field
                    onFieldSubmitted: _loading ? null : (_) => _sendResetEmail(), // Kirim saat submit
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground),
                    decoration: InputDecoration( // Gaya akan diambil dari inputDecorationTheme
                      labelText: 'Email Terdaftar',
                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant),
                      // border, borderRadius, dll. akan dari tema
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      // Validasi email yang lebih umum
                      final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
                      if (!emailRegex.hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32), // Jarak yang lebih konsisten
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendResetEmail,
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
                          : const Text('Kirim Email Reset'), // TextStyle akan dari tema tombol
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