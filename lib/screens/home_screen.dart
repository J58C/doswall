import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // Impor package
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../services/update_profile_service.dart';
import 'login_screen.dart';
import '../providers/theme_notifier.dart';
import '../theme/custom_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  bool _loadingGeotag = false;
  bool _updatingStatus = false;
  bool _isActive = false;
  List<String> _locationOptions = [];
  String? _selectedLocation;
  LatLng? _currentLatLng;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserStorage.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      if (user['lat'] != null && user['long'] != null && user['lat'] is num && user['long'] is num) {
        try {
          double lat = (user['lat'] as num).toDouble();
          double long = (user['long'] as num).toDouble();
          _currentLatLng = LatLng(lat, long);
          _isActive = true;
          if (user['geotag'] != null && user['geotag'] != '-' && user['geotag'] is String) {
            _locationOptions = [user['geotag']];
            _selectedLocation = user['geotag'];
          } else {
            _locationOptions = [];
            _selectedLocation = null;
          }
        } catch (e) {
          _currentLatLng = null;
          _isActive = false;
          _selectedLocation = null;
          _locationOptions = [];
        }
      } else {
        _isActive = false;
        _currentLatLng = null;
        _selectedLocation = null;
        _locationOptions = [];
      }
      _notesController.text = user['notes'] as String? ?? '';
    });
  }

  Future<void> _toggleActive(bool value) async {
    if (_user == null) return;
    setState(() => _loadingGeotag = true);
    final updatedUser = Map<String, dynamic>.from(_user!);

    if (value) {
      final result = await GeotagService.sendLocationAndGetName();
      if (!mounted) {
        setState(() => _loadingGeotag = false);
        return;
      }
      if (result['success']) {
        final locationList = List<String>.from(result['locationLists'] as List? ?? []);
        final lat = result['lat'] as double?;
        final long = result['long'] as double?;
        if (lat != null && long != null && locationList.isNotEmpty) {
          updatedUser..['geotag'] = locationList[0]..['lat'] = lat..['long'] = long..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim();
          setState(() {
            _locationOptions = locationList;
            _selectedLocation = locationList[0];
            _currentLatLng = LatLng(lat, long);
            _isActive = true;
          });
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Data lokasi tidak lengkap dari server.')));
          updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
          setState(() {
            _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false;
          });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gagal mendapatkan lokasi: ${result['message'] ?? 'Unknown error'}')));
        updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
        setState(() {
          _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false;
        });
      }
    } else {
      updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
      setState(() {
        _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false;
      });
    }
    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() { _user = updatedUser; _loadingGeotag = false; });
  }

  Future<void> _updateStatus(bool value) async {
    if (_user == null) return;
    setState(() => _updatingStatus = true);
    final updatedUser = Map<String, dynamic>.from(_user!);
    updatedUser['status'] = value ? 1 : 0;
    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() { _user = updatedUser; _updatingStatus = false; });
  }

  void _logout() async {
    await UserStorage.clearUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
  }

  void _saveData() async {
    if (_user == null) return;
    final currentNotes = _notesController.text.trim();
    final currentSelectedLocation = _selectedLocation ?? (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : '-');
    final updatedUser = Map<String, dynamic>.from(_user!)..['notes'] = currentNotes.isEmpty ? '-' : currentNotes..['geotag'] = currentSelectedLocation;
    if (_isActive && _currentLatLng != null) {
      updatedUser['lat'] = _currentLatLng!.latitude; updatedUser['long'] = _currentLatLng!.longitude;
    } else {
      updatedUser.remove('lat'); updatedUser.remove('long');
    }
    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() => _user = updatedUser);
    final result = await UpdateProfileService.sendUpdateProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success'] ? '✅ Profil berhasil diperbarui ke server.' : '❌ Gagal: ${result['message'] as String? ?? 'Terjadi kesalahan server'}'),
        backgroundColor: result['success'] ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    if (_currentLatLng == null) return const SizedBox.shrink();
    return Card(
      elevation: theme.cardTheme.elevation ?? 1.0,
      shape: theme.cardTheme.shape,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 150,
        child: FlutterMap(
          options: MapOptions(initialCenter: _currentLatLng!, initialZoom: 16, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(), // <-- PERUBAHAN DI SINI
              // Opsional: tambahkan userAgentPackageName jika direkomendasikan oleh dokumentasi flutter_map
              // Ganti 'com.example.app' dengan ID aplikasi Anda yang sebenarnya (dari build.gradle atau Info.plist).
              // userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(markers: [Marker(point: _currentLatLng!, width: 50, height: 50, child: Icon(Icons.location_pin, color: theme.colorScheme.error, size: 35))]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    if (_user == null) {
      return Scaffold(backgroundColor: colorScheme.surface, body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    bool isCurrentlyDark = themeNotifier.themeMode == ThemeMode.dark || (themeNotifier.themeMode == ThemeMode.system && theme.brightness == Brightness.dark);
    IconData themeIcon = isCurrentlyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    String themeTooltip = isCurrentlyDark ? 'Mode Terang' : 'Mode Gelap';

    final validSelectedLocation = (_isActive && _locationOptions.isNotEmpty && _locationOptions.toSet().contains(_selectedLocation))
        ? _selectedLocation
        : (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : null);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Beranda Doswall'),
        actions: [
          IconButton(icon: Icon(themeIcon), tooltip: themeTooltip, onPressed: () => themeNotifier.toggleTheme()),
          IconButton(icon: const Icon(Icons.logout_outlined), tooltip: 'Keluar', onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Text('Halo, ${_user!['name'] as String? ?? 'Pengguna'} 👋', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('Email: ${_user!['email'] as String? ?? '-'}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200))),
            Text('Role: ${_user!['role'] as String? ?? '-'}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200))),
            const SizedBox(height: 16),

            Card(
              elevation: theme.cardTheme.elevation,
              shape: theme.cardTheme.shape,
              color: theme.cardTheme.color,
              margin: theme.cardTheme.margin ?? const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 28),
                      title: Text('Geotag & Kehadiran', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      subtitle: Text('Aktifkan untuk update lokasi dan status.', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
                      trailing: _loadingGeotag
                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
                          : Switch(value: _isActive, onChanged: _toggleActive),
                    ),
                    if (_isActive) ...[
                      Divider(height: 20, thickness: 0.5, color: colorScheme.outline.withAlpha(100)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _user!['status'] == 1 ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                          color: _user!['status'] == 1 ? (theme.extension<CustomColors>()?.success ?? colorScheme.secondary) : colorScheme.error,
                          size: 28,
                        ),
                        title: Text('Status: ${_user!['status'] == 1 ? 'Hadir' : 'Tidak Hadir'}', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        subtitle: Text('Atur ketersediaan Anda.', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
                        trailing: _updatingStatus
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
                            : Switch(value: _user!['status'] == 1, onChanged: _updateStatus),
                      ),
                      const SizedBox(height: 12),
                      _buildMapCard(theme),
                      const SizedBox(height: 12),
                      if (_locationOptions.isNotEmpty)
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: validSelectedLocation,
                          items: _locationOptions.toSet().map((loc) => DropdownMenuItem<String>(
                            value: loc,
                            child: Text(loc, overflow: TextOverflow.ellipsis, style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedLocation = val),
                          decoration: const InputDecoration(labelText: 'Lokasi Terdeteksi'),
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                          dropdownColor: colorScheme.surfaceContainerHighest,
                        )
                      else if (_isActive)
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Mencari opsi lokasi...', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)))),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: const InputDecoration(labelText: 'Catatan Tambahan'),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text('Simpan Perubahan Profil'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/announcements'),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Lihat Pengumuman Penting'),
            ),
          ],
        ),
      ),
    );
  }
}