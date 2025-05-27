import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../services/update_profile_service.dart';
import 'login_screen.dart';

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

  Future<void> _loadUser() async {
    final user = await UserStorage.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _selectedLocation = user['geotag'] ?? '-';
      _notesController.text = user['notes'] ?? '-';
      if (user['lat'] != null && user['long'] != null) {
        _currentLatLng = LatLng(user['lat'], user['long']);
        _isActive = true;
      } else {
        _isActive = false;
      }
    });
  }

  Future<void> _toggleActive(bool value) async {
    if (_user == null) return;
    setState(() => _loadingGeotag = true);
    final updatedUser = Map<String, dynamic>.from(_user!);

    if (value) {
      final result = await GeotagService.sendLocationAndGetName();
      if (!mounted) return;

      if (result['success']) {
        final locationList = List<String>.from(result['locationLists']);
        final lat = result['lat'];
        final long = result['long'];

        updatedUser
          ..['geotag'] = locationList[0]
          ..['lat'] = lat
          ..['long'] = long
          ..['status'] = 0
          ..['notes'] = '-';

        setState(() {
          _locationOptions = locationList;
          _selectedLocation = locationList[0];
          _currentLatLng = LatLng(lat, long);
          _isActive = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal mendapatkan lokasi: ${result['message'] ?? 'Unknown error'}')),
        );
        updatedUser
          ..['geotag'] = '-'
          ..['status'] = 0
          ..['notes'] = '-'
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
        ..['status'] = 0
        ..['notes'] = '-'
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _saveData() async {
    if (_user == null) return;

    final updatedUser = Map<String, dynamic>.from(_user!)
      ..['notes'] = _notesController.text
      ..['geotag'] = _selectedLocation ?? '-';

    await UserStorage.saveUser(updatedUser);
    if (!mounted) return;
    setState(() => _user = updatedUser);

    final result = await UpdateProfileService.sendUpdateProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['success']
            ? '✅ Berhasil memperbarui profil ke server.'
            : '❌ Gagal: ${result['message']}'),
      ),
    );
  }

  Widget _buildMapCard() {
    if (_currentLatLng == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLatLng!,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
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
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Doswall'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Halo, ${_user!['name']} 👋',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Email: ${_user!['email']}', style: theme.textTheme.bodyMedium),
          Text('Role: ${_user!['role']}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.gps_fixed, color: Colors.blueAccent),
                    title: const Text('Geotag Aktif'),
                    subtitle: const Text('Menentukan lokasi dan status Anda.'),
                    trailing: Switch(
                      value: _isActive,
                      onChanged: _loadingGeotag ? null : _toggleActive,
                      activeColor: Colors.blueAccent,
                    ),
                  ),
                  if (_isActive) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.toggle_on, color: Colors.green),
                      title: Text('Status: ${_user!['status'] == 1 ? 'Tersedia' : 'Tidak Tersedia'}'),
                      subtitle: const Text('Atur ketersediaan untuk menerima pengumuman.'),
                      trailing: Switch(
                        value: _user!['status'] == 1,
                        onChanged: _updatingStatus ? null : _updateStatus,
                        activeColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMapCard(),
                    const SizedBox(height: 12),
                    if (_locationOptions.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: (_locationOptions.toSet().contains(_selectedLocation)) ? _selectedLocation : null,
                        items: _locationOptions
                            .toSet()
                            .map((loc) => DropdownMenuItem<String>(
                          value: loc,
                          child: Text(loc),
                        ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedLocation = val),
                        decoration: const InputDecoration(
                          labelText: 'Pilih Lokasi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saveData,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Perubahan'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/announcements'),
            icon: const Icon(Icons.announcement),
            label: const Text('Lihat Pengumuman'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}