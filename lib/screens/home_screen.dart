import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../models/geotag_response.dart';
import '../services/update_profile_service.dart';
import '../models/update_profile_response.dart';
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
            _locationOptions = []; _selectedLocation = null;
          }
        } catch (e) {
          _currentLatLng = null; _isActive = false; _selectedLocation = null; _locationOptions = [];
        }
      } else {
        _isActive = false; _currentLatLng = null; _selectedLocation = null; _locationOptions = [];
      }
      _notesController.text = user['notes'] as String? ?? '';
    });
  }

  Future<void> _toggleActive(bool value) async {
    if (_user == null) return;
    setState(() => _loadingGeotag = true);
    final updatedUser = Map<String, dynamic>.from(_user!);

    if (value) {
      final GeotagResponse result = await GeotagService.fetchGeotagData();
      if (!mounted) { setState(() => _loadingGeotag = false); return; }
      if (result.success) {
        final locationList = result.locationLists ?? [];
        final lat = result.lat;
        final long = result.long;
        if (lat != null && long != null && locationList.isNotEmpty) {
          updatedUser..['geotag'] = locationList[0]..['lat'] = lat..['long'] = long..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim();
          setState(() {
            _locationOptions = locationList; _selectedLocation = locationList[0]; _currentLatLng = LatLng(lat, long); _isActive = true;
          });
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? '❌ Data lokasi tidak lengkap dari server.')));
          updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
          setState(() { _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false; });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? '❌ Gagal mendapatkan lokasi.')));
        updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
        setState(() { _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false; });
      }
    } else {
      updatedUser..['geotag'] = '-'..['status'] = _user!['status'] ?? 0..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()..remove('lat')..remove('long');
      setState(() { _locationOptions = []; _selectedLocation = null; _currentLatLng = null; _isActive = false; });
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

  void _handleChangePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ubah password belum diimplementasikan.'), behavior: SnackBarBehavior.floating),
    );
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
    final UpdateProfileResponse result = await UpdateProfileService.updateUserProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? (result.message ?? '✅ Profil berhasil diperbarui.') : (result.message ?? '❌ Gagal memperbarui profil.')),
        backgroundColor: result.success ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.errorContainer,
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
        height: 120,
        child: FlutterMap(
          options: MapOptions(initialCenter: _currentLatLng!, initialZoom: 16, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', tileProvider: CancellableNetworkTileProvider()),
            MarkerLayer(markers: [Marker(point: _currentLatLng!, width: 40, height: 40, child: Icon(Icons.location_pin, color: theme.colorScheme.error, size: 30))]),
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

    final Brightness currentPlatformBrightness = MediaQuery.platformBrightnessOf(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (themeNotifier.themeMode == ThemeMode.system && currentPlatformBrightness == Brightness.dark);

    IconData themeIconData = isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    String themeTooltip = isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap';

    final validSelectedLocation = (_isActive && _locationOptions.isNotEmpty && _locationOptions.toSet().contains(_selectedLocation))
        ? _selectedLocation
        : (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : null);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Beranda Doswall'),
        actions: [
          IconButton(icon: Icon(Icons.campaign_outlined, color: colorScheme.onPrimary), tooltip: 'Pengumuman', onPressed: () => Navigator.pushNamed(context, '/announcements')),
          IconButton(
              icon: Icon(themeIconData, color: colorScheme.onPrimary),
              tooltip: themeTooltip,
              onPressed: () {
                themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light);
              }
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onPrimary),
            tooltip: "Opsi Lainnya",
            onSelected: (value) {
              if (value == 'change_password') {
                _handleChangePassword();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock_person_outlined),
                  title: Text('Ubah Password'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app_rounded),
                  title: Text('Keluar'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/unnes_logo.jpg',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 50, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Halo,', style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))), // Menggunakan onSurface
                        Text(
                          _user!['name'] as String? ?? 'Pengguna',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface), // Menggunakan onSurface
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Email: ${_user!['email'] as String? ?? '-'}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))), // Menggunakan onSurface
              Text('Role: ${_user!['role'] as String? ?? '-'}', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(150))), // Menggunakan onSurface
              const SizedBox(height: 16),

              Card(
                elevation: theme.cardTheme.elevation,
                shape: theme.cardTheme.shape,
                color: theme.cardTheme.color,
                margin: theme.cardTheme.margin ?? const EdgeInsets.symmetric(vertical: 6.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 26),
                        title: Text('Geotag & Kehadiran', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                        subtitle: Text('Status lokasi dan kehadiran Anda.', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180))),
                        trailing: _loadingGeotag
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: colorScheme.primary))
                            : Switch(value: _isActive, onChanged: _toggleActive, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                      if (_isActive) ...[
                        Divider(height: 16, thickness: 0.5, color: colorScheme.outline.withAlpha(80)),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _user!['status'] == 1 ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                            color: _user!['status'] == 1 ? (theme.extension<CustomColors>()?.success ?? colorScheme.secondary) : colorScheme.error,
                            size: 26,
                          ),
                          title: Text('Status: ${_user!['status'] == 1 ? 'Hadir' : 'Tidak Hadir'}', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          trailing: _updatingStatus
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: colorScheme.primary))
                              : Switch(value: _user!['status'] == 1, onChanged: _updateStatus, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                        const SizedBox(height: 8),
                        _buildMapCard(theme),
                        const SizedBox(height: 8),
                        if (_locationOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: validSelectedLocation,
                            items: _locationOptions.toSet().map((loc) => DropdownMenuItem<String>(value: loc, child: Text(loc, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedLocation = val),
                            decoration: const InputDecoration(labelText: 'Lokasi Terdeteksi', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                            dropdownColor: colorScheme.surfaceContainerHighest,
                          )
                        else if (_isActive)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Mencari opsi lokasi...', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                          decoration: const InputDecoration(labelText: 'Catatan Tambahan (opsional)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isActive)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveData,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Simpan Perubahan Profil'),
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}