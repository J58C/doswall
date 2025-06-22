import 'package:flutter/material.dart';

class HeaderCard extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool isActive;
  final bool isFetchingLocation;
  final ValueChanged<bool> onToggle;

  const HeaderCard({
    super.key,
    required this.user,
    required this.isActive,
    required this.isFetchingLocation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUserProfileHeader(context),
        const SizedBox(height: 24.0),
        _buildGeotagControlCard(context),
      ],
    );
  }

  Widget _buildUserProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat Datang,', style: theme.textTheme.bodyLarge),
          Text(
            user!['name'] as String? ?? 'Pengguna',
            style: theme.textTheme.headlineLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGeotagControlCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.my_location_rounded,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Presensi', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? 'Layanan presensi diaktifkan'
                        : 'Aktifkan layanan presensi',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: isActive,
              onChanged: isFetchingLocation ? null : onToggle,
            ),
          ],
        ),
      ),
    );
  }
}