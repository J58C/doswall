import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/view_state.dart';
import '../view_models/profile_view_model.dart';

import '../providers/theme_notifier.dart';
import './login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUser();
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await context.read<ProfileViewModel>().logout();

              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text('Keluar'),
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
    final viewModel = context.watch<ProfileViewModel>();
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = theme.brightness == Brightness.dark;

    Color appBarColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    Color onAppBarColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(50),
        title: Text('Profil Pengguna', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => themeNotifier.toggleTheme(theme.brightness),
            color: onAppBarColor,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildArtisticBackground(context, isDark),
          _buildBody(viewModel),
        ],
      ),
    );
  }

  Widget _buildBody(ProfileViewModel viewModel) {
    switch (viewModel.state) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return Center(child: Text(viewModel.errorMessage));
      case ViewState.success:
        return _buildProfileContent(context, viewModel);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileContent(BuildContext context, ProfileViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileHeader(Theme.of(context), viewModel),
        const SizedBox(height: 24),
        _buildActionList(Theme.of(context)),
      ],
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ProfileViewModel viewModel) {
    final user = viewModel.user!;
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person_outline, size: 56, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(user['name'] ?? 'Pengguna', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(user['email'] ?? '-', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withAlpha(180))),
            const SizedBox(height: 12),
            Chip(
              label: Text((user['role'] as String?)?.toUpperCase() ?? 'USER'),
              backgroundColor: theme.colorScheme.tertiaryContainer,
              labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onTertiaryContainer),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList(ThemeData theme) {
    return Card(
      elevation: 2, shadowColor: Colors.black.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Ubah Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleChangePassword,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text('Keluar', style: TextStyle(color: theme.colorScheme.error)),
            onTap: _logout,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }
  Widget _buildArtisticBackground(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Stack(children: [ Positioned(top: -120, right: -180, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withAlpha(isDark ? 30 : 50)))), Positioned(bottom: -150, left: -100, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, color: secondary.withAlpha(isDark ? 35 : 55))))]);
  }
}