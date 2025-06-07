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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _isActive = false;
  bool _isFetchingLocation = false;
  bool _updatingStatus = false;
  List<String> _locationOptions = [];
  String? _selectedLocation;
  LatLng? _currentLatLng;
  final TextEditingController _notesController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUser();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserStorage.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      bool shouldBeActive = user['lat'] != null && user['long'] != null;
      if (shouldBeActive) {
        _isActive = true;
        _fetchLocationData();
      } else {
        _isActive = false;
      }
      _notesController.text = user['notes'] as String? ?? '';
    });
  }

  void _toggleActive(bool value) {
    if (value) {
      setState(() => _isActive = true);
      _fetchLocationData();
    } else {
      _showConfirmationDialog(
        title: 'Nonaktifkan Presensi?',
        content: 'Data lokasi dan kehadiran Anda akan dihapus untuk sesi ini.',
        onConfirm: () {
          setState(() {
            _isActive = false;
            _currentLatLng = null;
            _locationOptions = [];
            _selectedLocation = null;
          });
          final updatedUser = Map<String, dynamic>.from(_user!)
            ..['geotag'] = '-'
            ..remove('lat')
            ..remove('long');
          UserStorage.saveUser(updatedUser);
          setState(() => _user = updatedUser);
        },
      );
    }
  }

  Future<void> _fetchLocationData() async {
    setState(() => _isFetchingLocation = true);
    try {
      final GeotagResponse result = await GeotagService.fetchGeotagData();
      if (!mounted) return;
      if (result.success && result.lat != null && result.long != null && (result.locationLists?.isNotEmpty ?? false)) {
        final uniqueLocations = result.locationLists!.toSet().toList();
        setState(() {
          _currentLatLng = LatLng(result.lat!, result.long!);
          _locationOptions = uniqueLocations;
          _selectedLocation = uniqueLocations[0];
          final updatedUser = Map<String, dynamic>.from(_user!)
            ..['geotag'] = _selectedLocation
            ..['lat'] = result.lat
            ..['long'] = result.long;
          UserStorage.saveUser(updatedUser);
          _user = updatedUser;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? '❌ Gagal mendapatkan lokasi.')));
          setState(() => _isActive = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Terjadi error: ${e.toString()}')));
        setState(() => _isActive = false);
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
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
        backgroundColor: result.success
            ? Theme.of(context).extension<CustomColors>()?.success
            : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  void _logout() {
    _showConfirmationDialog(
        title: 'Konfirmasi Keluar',
        content: 'Apakah Anda yakin ingin keluar dari aplikasi?',
        onConfirm: () async {
          await UserStorage.clearUser();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
        });
  }

  void _handleChangePassword() => Navigator.pushNamed(context, '/change-password');
  void _handleAdminAction() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasi ke Panel Admin...')));
  void _handleAnnouncements() => Navigator.pushNamed(context, '/announcements');

  void _showConfirmationDialog({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(onPressed: () {
          Navigator.of(context).pop();
          onConfirm();
        }, child: const Text('Konfirmasi')),
      ],
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark || (themeNotifier.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/images/unnes_logo.jpg', errorBuilder: (c, e, s) => const Icon(Icons.school)),
        ),
        title: const Text('Doswall'),
        actions: [
          IconButton(
            icon: Icon(isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Presensi', icon: Icon(Icons.location_on_outlined)),
            Tab(text: 'Profil', icon: Icon(Icons.person_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPresenceTab(context),
          _buildProfileTab(context),
        ],
      ),
    );
  }

  Widget _buildPresenceTab(BuildContext context) {
    final theme = Theme.of(context);
    bool isAdminOrSuperAdmin = _user!['role'] == 'admin' || _user!['role'] == 'superadmin';

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchLocationData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUserProfileHeader(theme),
                const SizedBox(height: 16),
                _buildGeotagControlCard(theme),
                const SizedBox(height: 16),
                _buildPresenceDetailsCard(theme),
              ],
            ),
          ),
        ),
        _buildCustomFloatingActionBar(context, isAdminOrSuperAdmin),
      ],
    );
  }

  Widget _buildCustomFloatingActionBar(BuildContext context, bool isAdmin) {
    if (_tabController.index != 0) return const SizedBox.shrink();

    Widget? saveButton;
    Widget? adminButton;
    final theme = Theme.of(context);

    if (_isActive) {
      saveButton = FloatingActionButton.extended(
        heroTag: 'fab_save',
        onPressed: _isFetchingLocation ? null : _saveData,
        label: const Text('Simpan'),
        icon: _isFetchingLocation
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_alt_outlined),
      );
    }

    if (isAdmin) {
      if (_isActive) {
        adminButton = FloatingActionButton(
          heroTag: 'fab_admin',
          onPressed: _handleAdminAction,
          tooltip: 'Admin Area',
          backgroundColor: theme.colorScheme.tertiaryContainer,
          foregroundColor: theme.colorScheme.onTertiaryContainer,
          child: const Icon(Icons.admin_panel_settings_outlined),
        );
      } else {
        adminButton = FloatingActionButton.extended(
          heroTag: 'fab_admin',
          onPressed: _handleAdminAction,
          label: const Text('Admin'),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          backgroundColor: theme.colorScheme.tertiaryContainer,
          foregroundColor: theme.colorScheme.onTertiaryContainer,
        );
      }
    }

    Widget centerCluster;
    if (adminButton != null && saveButton != null) {
      centerCluster = Row(
        mainAxisSize: MainAxisSize.min,
        children: [adminButton, const SizedBox(width: 12), saveButton],
      );
    } else {
      centerCluster = adminButton ?? saveButton ?? const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          const Spacer(),
          centerCluster,
          const Spacer(),
          FloatingActionButton(
            heroTag: 'fab_announcements',
            onPressed: _handleAnnouncements,
            tooltip: 'Pengumuman',
            child: const Icon(Icons.campaign_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
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
                  child: Icon(Icons.person_outline, size: 48, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Text(_user!['name'] ?? 'Pengguna', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(_user!['email'] ?? '-', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Chip(
                  label: Text(_user!['role']?.toString().toUpperCase() ?? 'USER'),
                  backgroundColor: theme.colorScheme.primary.withAlpha(50),
                  labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildUserProfileHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat Datang,', style: theme.textTheme.bodyMedium),
              Text(
                _user!['name'] as String? ?? 'Pengguna',
                style: theme.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Chip(
          avatar: Icon(
            Icons.circle,
            size: 12,
            color: _isActive
                ? theme.extension<CustomColors>()?.success
                : theme.colorScheme.error,
          ),
          label: Text(_isActive ? 'AKTIF' : 'NONAKTIF'),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
          backgroundColor: _isActive
              ? theme.extension<CustomColors>()?.success?.withAlpha(50)
              : theme.colorScheme.error.withAlpha(50),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildGeotagControlCard(ThemeData theme) {
    return Card(
      elevation: 2.0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.my_location_rounded,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          title: Text('Status Presensi', style: theme.textTheme.titleLarge),
          subtitle: Text(_isActive ? 'Presensi diaktifkan' : 'Aktifkan untuk melapor'),
          trailing: Switch(
            value: _isActive,
            onChanged: _toggleActive,
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceDetailsCard(ThemeData theme) {
    final validSelectedLocation = (_locationOptions.isNotEmpty && _locationOptions.contains(_selectedLocation))
        ? _selectedLocation
        : (_locationOptions.isNotEmpty ? _locationOptions[0] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              _user!['status'] == 1 ? Icons.check_circle_outline : Icons.highlight_off_outlined,
              color: _user!['status'] == 1 ? theme.extension<CustomColors>()?.success : theme.colorScheme.error,
              size: 28,
            ),
            title: const Text('Status Kehadiran'),
            trailing: _updatingStatus
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                : Switch(
              value: _user!['status'] == 1,
              onChanged: _updateStatus,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Lokasi Terdeteksi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildMapCard(theme),
        const SizedBox(height: 16),
        if (_isActive)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: validSelectedLocation,
                    items: _locationOptions.map((loc) => DropdownMenuItem<String>(value: loc, child: Text(loc, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val),
                    decoration: const InputDecoration(labelText: 'Pilih Lokasi Terdekat'),
                    disabledHint: const Text('Tidak ada lokasi tersedia'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Catatan Tambahan', hintText: 'Mis: Sedang WFH atau dinas luar'),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    Widget mapContent;
    if (_isFetchingLocation) {
      mapContent = const Center(child: CircularProgressIndicator());
    } else if (_currentLatLng == null) {
      mapContent = Center(child: Padding(padding: const EdgeInsets.all(8.0),
          child: Text('Lokasi tidak ditemukan.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center)));
    } else {
      mapContent = FlutterMap(
        options: MapOptions(
          initialCenter: _currentLatLng!,
          initialZoom: 17.5,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', tileProvider: CancellableNetworkTileProvider()),
          MarkerLayer(markers: [Marker(point: _currentLatLng!, width: 40, height: 40, child: Icon(Icons.location_pin, color: theme.colorScheme.error, size: 40))]),
        ],
      );
    }
    return Card(clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero, child: SizedBox(height: 150, child: mapContent));
  }
}