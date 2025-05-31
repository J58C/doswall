import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/user_storage.dart'; // Pastikan path ini benar
import '../services/geotag_service.dart'; // Pastikan path ini benar
import '../services/update_profile_service.dart'; // Pastikan path ini benar
import 'login_screen.dart'; // Pastikan path ini benar

// Impor CustomColors dari main.dart jika belum ada (atau pindahkan definisinya ke file terpisah)
// Untuk contoh ini, kita asumsikan CustomColors dapat diakses atau Anda akan menambahkannya.
// Jika CustomColors ada di main.dart, Anda mungkin perlu cara untuk mengaksesnya,
// atau cara yang lebih baik adalah memindahkan CustomColors ke file tersendiri dan mengimpornya.
// Untuk saat ini, kita akan menggunakan fallback jika theme.extension<CustomColors>() null.
// import '../main.dart'; // HINDARI SIKLUS IMPOR, JANGAN IMPOR main.dart KE SCREEN

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

  // --- LOGIKA ANDA TETAP SAMA ---
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
          // Inisialisasi _locationOptions dan _selectedLocation dari user storage jika ada
          if (user['geotag'] != null && user['geotag'] != '-' && user['geotag'] is String) {
            _locationOptions = [user['geotag']]; // Asumsi geotag dari storage adalah satu lokasi awal
            _selectedLocation = user['geotag'];
          } else {
            _locationOptions = [];
            _selectedLocation = null;
          }
        } catch (e) {
          print("Error parsing lat/long from user storage: $e");
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
          updatedUser
            ..['geotag'] = locationList[0]
            ..['lat'] = lat
            ..['long'] = long
            ..['status'] = _user!['status'] ?? 0
            ..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim();

          setState(() {
            _locationOptions = locationList;
            _selectedLocation = locationList[0];
            _currentLatLng = LatLng(lat, long);
            _isActive = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Data lokasi tidak lengkap dari server.')),
          );
          updatedUser
            ..['geotag'] = '-'
            ..['status'] = _user!['status'] ?? 0
            ..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()
            ..remove('lat')
            ..remove('long');
          setState(() {
            _locationOptions = [];
            _selectedLocation = null;
            _currentLatLng = null;
            _isActive = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal mendapatkan lokasi: ${result['message'] ?? 'Unknown error'}')),
        );
        updatedUser
          ..['geotag'] = '-'
          ..['status'] = _user!['status'] ?? 0
          ..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()
          ..remove('lat')
          ..remove('long');
        setState(() {
          _locationOptions = [];
          _selectedLocation = null;
          _currentLatLng = null;
          _isActive = false;
        });
      }
    } else {
      updatedUser
        ..['geotag'] = '-'
        ..['status'] = _user!['status'] ?? 0
        ..['notes'] = _notesController.text.trim().isEmpty ? '-' : _notesController.text.trim()
        ..remove('lat')
        ..remove('long');
      setState(() {
        _locationOptions = [];
        _selectedLocation = null;
        _currentLatLng = null;
        _isActive = false;
      });
    }

    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() {
      _user = updatedUser;
      _loadingGeotag = false;
    });
  }

  Future<void> _updateStatus(bool value) async {
    if (_user == null) return;
    setState(() => _updatingStatus = true);

    final updatedUser = Map<String, dynamic>.from(_user!);
    updatedUser['status'] = value ? 1 : 0;
    await UserStorage.saveUser(updatedUser);

    if (!mounted) return;
    setState(() {
      _user = updatedUser;
      _updatingStatus = false;
    });
  }

  void _logout() async {
    await UserStorage.clearUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _saveData() async {
    if (_user == null) return;
    final currentNotes = _notesController.text.trim();
    final currentSelectedLocation = _selectedLocation ?? (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : '-');

    final updatedUser = Map<String, dynamic>.from(_user!)
      ..['notes'] = currentNotes.isEmpty ? '-' : currentNotes
      ..['geotag'] = currentSelectedLocation;

    if (_isActive && _currentLatLng != null) {
      updatedUser['lat'] = _currentLatLng!.latitude;
      updatedUser['long'] = _currentLatLng!.longitude;
    } else {
      updatedUser.remove('lat');
      updatedUser.remove('long');
    }

    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() => _user = updatedUser);

    final result = await UpdateProfileService.sendUpdateProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success']
            ? '✅ Berhasil memperbarui profil ke server.'
            : '❌ Gagal: ${result['message'] as String? ?? 'Terjadi kesalahan server'}'),
        backgroundColor: result['success']
            ? Theme.of(context).colorScheme.secondaryContainer // Menggunakan warna dari tema
            : Theme.of(context).colorScheme.errorContainer, // Menggunakan warna dari tema
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // --- AKHIR LOGIKA ANDA ---

  Widget _buildMapCard(ThemeData theme) {
    if (_currentLatLng == null) return const SizedBox.shrink();
    return Card(
      elevation: theme.cardTheme.elevation ?? 2.0, // Menggunakan elevasi dari tema Card
      shape: theme.cardTheme.shape, // Menggunakan shape dari tema Card
      clipBehavior: Clip.antiAlias, // Untuk border radius pada child
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _currentLatLng!,
            initialZoom: 17,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // userAgentPackageName: 'dev.fleaflet.flutter_map.example', // Opsional, jika diperlukan
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLatLng!,
                  width: 60,
                  height: 60,
                  child: Icon(
                    Icons.location_pin,
                    color: theme.colorScheme.error, // Menggunakan warna error dari tema
                    size: 40,
                  ),
                ),
              ],
            ),
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

    if (_user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    // Untuk menghindari error jika _selectedLocation tidak ada di _locationOptions setelah _isActive false
    final validSelectedLocation = (_isActive && _locationOptions.isNotEmpty && _locationOptions.toSet().contains(_selectedLocation))
        ? _selectedLocation
        : (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : null);


    return Scaffold(
      backgroundColor: colorScheme.surface, // Menggunakan warna background dari tema
      appBar: AppBar(
        // Gaya AppBar akan diambil dari appBarTheme di main.dart
        title: const Text('Beranda Doswall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Keluar',
            onPressed: _logout,
            // Warna ikon akan dari appBarTheme.iconTheme atau colorScheme.onPrimary
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Halo, ${_user!['name'] as String? ?? 'Pengguna'} 👋',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text('Email: ${_user!['email'] as String? ?? '-'}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200))),
            Text('Role: ${_user!['role'] as String? ?? '-'}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(200))),
            const SizedBox(height: 20),

            Card(
              // Gaya Card akan diambil dari cardTheme di main.dart
              elevation: theme.cardTheme.elevation,
              shape: theme.cardTheme.shape,
              color: theme.cardTheme.color, // Menggunakan warna card dari tema
              margin: theme.cardTheme.margin, // Menggunakan margin dari tema
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
                      title: Text(
                        'Geotag & Kehadiran',
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        'Aktifkan untuk menentukan lokasi dan status kehadiran Anda.',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                      ),
                      trailing: _loadingGeotag
                          ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
                          : Switch(
                        value: _isActive,
                        onChanged: _toggleActive,
                        // Gaya Switch akan diambil dari switchTheme di main.dart
                      ),
                    ),
                    if (_isActive) ...[
                      Divider(height: 24, thickness: 0.5, color: colorScheme.outline.withAlpha(100)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _user!['status'] == 1 ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                          color: _user!['status'] == 1
                              ? (theme.extension<CustomColors>()?.success ?? colorScheme.secondary) // Menggunakan CustomColors
                              : colorScheme.error,
                        ),
                        title: Text(
                          'Status Kehadiran: ${_user!['status'] == 1 ? 'Hadir (Tersedia)' : 'Tidak Hadir'}',
                          style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          'Atur ketersediaan untuk pengumuman.',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                        ),
                        trailing: _updatingStatus
                            ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
                            : Switch(
                          value: _user!['status'] == 1,
                          onChanged: _updateStatus,
                          // Gaya Switch akan diambil dari switchTheme
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMapCard(theme),
                      const SizedBox(height: 16),
                      if (_locationOptions.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: validSelectedLocation,
                          items: _locationOptions.toSet().map((loc) => DropdownMenuItem<String>(
                            value: loc,
                            child: Text(loc, style: textTheme.bodyLarge), // Warna teks akan dari tema dropdown
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedLocation = val),
                          decoration: InputDecoration( // Gaya akan dari inputDecorationTheme
                            labelText: 'Pilih Lokasi Terdeteksi',
                            // prefixIcon: Icon(Icons.arrow_drop_down_circle_outlined, color: colorScheme.onSurfaceVariant),
                          ),
                          // Style dropdown akan mengikuti tema, termasuk dropdownColor dari theme
                          dropdownColor: colorScheme.surfaceContainerHighest,
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        )
                      else if (_isActive)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Sedang mencari opsi lokasi atau tidak ada yang terdeteksi...',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(180)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration( // Gaya akan dari inputDecorationTheme
                          labelText: 'Catatan Tambahan (opsional)',
                          // prefixIcon: Icon(Icons.note_alt_outlined, color: colorScheme.onSurfaceVariant),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Perubahan Profil'),
              // Gaya akan diambil dari elevatedButtonTheme di main.dart
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/announcements'),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Lihat Pengumuman Penting'),
              // Gaya akan diambil dari outlinedButtonTheme di main.dart
            ),
          ],
        ),
      ),
    );
  }
}