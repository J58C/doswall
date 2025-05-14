import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_storage.dart';
import '../services/geotag_service.dart';
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
    setState(() {
      _user = user;
      _selectedLocation = user?['geotag'] ?? '-';
      _notesController.text = user?['notes'] ?? '-';
      if (user?['lat'] != null && user?['long'] != null) {
        _currentLatLng = LatLng(user!['lat'], user['long']);
        _isActive = true;
      } else {
        _isActive = false;
      }
    });
  }

  Future<void> _toggleActive(bool value) async {
    if (_user == null) return;

    setState(() {
      _isActive = value;
      _loadingGeotag = value;
    });

    final updatedUser = Map<String, dynamic>.from(_user!);

    if (value) {
      final result = await GeotagService.sendLocationAndGetName();
      if (result['success']) {
        final locationList = List<String>.from(result['locationLists']);
        final lat = result['lat'];
        final long = result['long'];

        updatedUser['geotag'] = locationList[0];
        updatedUser['lat'] = lat;
        updatedUser['long'] = long;
        updatedUser['status'] = 0;
        updatedUser['notes'] = '-';

        _locationOptions = locationList;
        _selectedLocation = locationList[0];
        _currentLatLng = LatLng(lat, long);
      } else {
        updatedUser['geotag'] = '-';
        updatedUser['status'] = 0;
        updatedUser['notes'] = '-';
        updatedUser.remove('lat');
        updatedUser.remove('long');
        _locationOptions = [];
        _selectedLocation = null;
        _currentLatLng = null;
        _isActive = false; // pastikan state mati jika gagal ambil lokasi
      }
    } else {
      updatedUser['geotag'] = '-';
      updatedUser['status'] = 0;
      updatedUser['notes'] = '-';
      updatedUser.remove('lat');
      updatedUser.remove('long');
      _locationOptions = [];
      _selectedLocation = null;
      _currentLatLng = null;
    }

    await UserStorage.saveUser(updatedUser);

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
    final updatedUser = Map<String, dynamic>.from(_user!);
    updatedUser['notes'] = _notesController.text;
    updatedUser['geotag'] = _selectedLocation ?? '-';
    await UserStorage.saveUser(updatedUser);
    setState(() => _user = updatedUser);
  }

  Widget _buildMap() {
    if (_currentLatLng == null) return const SizedBox(height: 200);

    return SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _currentLatLng!,
          initialZoom: 17,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLatLng!,
                width: 80,
                height: 80,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Doswall', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar",
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Selamat datang, ${_user!['name']} 👋',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Akunmu telah berhasil masuk ke sistem.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoTile(Icons.email, "Email", _user!['email']),
                  _infoTile(Icons.person, "Role", _user!['role']),
                  const Divider(height: 30),
                  _switchTile(
                    icon: Icons.gps_fixed,
                    title: "Aktifkan Geotag",
                    value: _isActive,
                    onChanged: _toggleActive,
                  ),
                  if (_isActive) ...[
                    const SizedBox(height: 12),
                    _switchTile(
                      icon: Icons.power_settings_new,
                      title: "Status: ${_user!['status'] == 1 ? 'Available' : 'Unavailable'}",
                      value: _user!['status'] == 1,
                      onChanged: _updatingStatus ? null : _updateStatus,
                    ),
                    const SizedBox(height: 12),
                    _buildMap(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _loadingGeotag
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Builder(builder: (_) {
                            if (!_locationOptions.contains(_selectedLocation)) {
                              _selectedLocation = _locationOptions.isNotEmpty
                                  ? _locationOptions.first
                                  : null;
                            }

                            return DropdownButton<String>(
                              value: _selectedLocation,
                              isExpanded: true,
                              items: _locationOptions.toSet().map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedLocation = newValue!;
                                });
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}