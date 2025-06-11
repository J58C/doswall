import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_storage.dart';
import '../providers/theme_notifier.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserStorage.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);

              await UserStorage.clearUser();

              await navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: Icon(isEffectivelyDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(
                isEffectivelyDark ? Brightness.dark : Brightness.light),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person_outline,
                        size: 48, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(_user!['name'] ?? 'Pengguna',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(_user!['email'] ?? '-', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_user!['role']?.toString().toUpperCase() ?? 'USER'),
                    backgroundColor: theme.colorScheme.primary.withAlpha(50),
                    labelStyle: TextStyle(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Ubah Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _handleChangePassword,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.exit_to_app_rounded, color: theme.colorScheme.error),
                  title: Text('Keluar', style: TextStyle(color: theme.colorScheme.error)),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}