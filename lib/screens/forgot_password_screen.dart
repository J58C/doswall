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

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final res = await http.post(
      Uri.parse('https://sigmaskibidi.my.id/appkey/password/mailpw'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'appkey': 'DOEGUSAPPACCESSCORS',
      }),
    );

    setState(() => _loading = false);

    final success = res.statusCode == 200;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Email Terkirim' : 'Gagal'),
        content: Text(success
            ? 'Link reset password telah dikirim ke email kamu.'
            : 'Gagal mengirim email. Pastikan email benar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Lupa Password')),
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
                children: [
                  const Icon(Icons.lock_reset, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan email kamu. Kami akan mengirimkan tautan untuk reset password.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          : const Text('Kirim Email', style: TextStyle(fontSize: 16)),
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