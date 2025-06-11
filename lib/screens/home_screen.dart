import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../models/geotag_response.dart';
import '../services/update_profile_service.dart';
import '../models/update_profile_response.dart';
import '../providers/theme_notifier.dart';
import '../theme/custom_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _user;
  bool _isActive = false;
  bool _isFetchingLocation = false;
  bool _updatingStatus = false;
  List<String> _locationOptions = [];
  String? _selectedLocation;
  LatLng? _currentLatLng;
  final TextEditingController _notesController = TextEditingController();
  String? _storedNotes;
  final FocusNode _notesFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _notesController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _scrollController.dispose();
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
      _storedNotes = user['notes'] as String?;
    });
  }

  // --- PERUBAHAN UTAMA ADA DI METHOD INI ---
  void _toggleActive(bool value) {
    if (value) {
      setState(() => _isActive = true);
      _fetchLocationData();
    } else {
      _showConfirmationDialog(
        title: 'Nonaktifkan Presensi?',
        content: 'Status Anda juga akan diubah menjadi "Unavailable". Lanjutkan?',
        onConfirm: () async {
          final messenger = ScaffoldMessenger.of(context);
          final theme = Theme.of(context);

          final updatedUser = Map<String, dynamic>.from(_user!)
            ..['geotag'] = '-'
            ..['status'] = 0
            ..remove('lat')
            ..remove('long');

          await UserStorage.saveUser(updatedUser);

          if (!mounted) return;
          setState(() {
            _isActive = false;
            _currentLatLng = null;
            _locationOptions = [];
            _selectedLocation = null;
            _user = updatedUser;
          });

          final result = await UpdateProfileService.updateUserProfile();
          if (!mounted) return;

          messenger.showSnackBar(
            SnackBar(
              content: Text(result.success ? '✅ Presensi dinonaktifkan & profil diperbarui.' : '❌ Gagal memperbarui profil.'),
              backgroundColor: result.success
                  ? theme.extension<CustomColors>()?.success
                  : theme.colorScheme.errorContainer,
            ),
          );
        },
      );
    }
  }

  Future<void> _fetchLocationData() async {
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(SnackBar(content: Text(result.message ?? '❌ Gagal mendapatkan lokasi.')));
        setState(() => _isActive = false);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('❌ Terjadi error: ${e.toString()}')));
      setState(() => _isActive = false);
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
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

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

    final UpdateProfileResponse result = await UpdateProfileService.updateUserProfile();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success ? (result.message ?? '✅ Profil berhasil diperbarui.') : (result.message ?? '❌ Gagal memperbarui profil.')),
        backgroundColor: result.success
            ? theme.extension<CustomColors>()?.success
            : theme.colorScheme.errorContainer,
      ),
    );
  }

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

    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark || (themeNotifier.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/unnes_logo.jpg',
                height: 26,
                errorBuilder: (c, e, s) => const Icon(Icons.school, size: 26),
              ),
              const SizedBox(width: 8),
              Text(
                  'Doswall',
                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: theme.appBarTheme.foregroundColor,
                  )
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Buka Profil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: _buildPresenceTab(context),
    );
  }

  Widget _buildPresenceTab(BuildContext context) {
    final theme = Theme.of(context);
    bool isAdminOrSuperAdmin = _user!['role'] == 'admin' || _user!['role'] == 'superadmin';

    Widget saveButton = AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      scale: _isActive ? 1.0 : 0.0,
      child: FloatingActionButton.extended(
        heroTag: 'fab_save',
        onPressed: _isFetchingLocation ? null : _saveData,
        label: const Text('Simpan'),
        icon: _isFetchingLocation
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_alt_outlined),
      ),
    );

    Widget? adminButton;
    if (isAdminOrSuperAdmin) {
      adminButton = AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isActive
            ? FloatingActionButton(
          key: const ValueKey('admin_small'),
          heroTag: 'fab_admin',
          onPressed: _handleAdminAction,
          tooltip: 'Admin Area',
          backgroundColor: theme.colorScheme.tertiaryContainer,
          foregroundColor: theme.colorScheme.onTertiaryContainer,
          child: const Icon(Icons.admin_panel_settings_outlined),
        )
            : FloatingActionButton.extended(
          key: const ValueKey('admin_large'),
          heroTag: 'fab_admin',
          onPressed: _handleAdminAction,
          label: const Text('Admin'),
          icon: const Icon(Icons.admin_panel_settings_outlined),
          backgroundColor: theme.colorScheme.tertiaryContainer,
          foregroundColor: theme.colorScheme.onTertiaryContainer,
        ),
      );
    }

    Widget? adminPlaceholder;
    if (adminButton != null && _isActive) {
      adminPlaceholder = const SizedBox(width: 56);
    }

    Widget centerCluster;
    if (adminButton != null && _isActive) {
      centerCluster = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminButton,
          const SizedBox(width: 12),
          saveButton,
          const SizedBox(width: 12),
          adminPlaceholder ?? const SizedBox.shrink(),
        ],
      );
    } else {
      centerCluster = adminButton ?? saveButton;
    }

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserProfileHeader(theme),
              const SizedBox(height: 24.0),
              _buildGeotagControlCard(theme),
              const SizedBox(height: 16.0),
              _buildPresenceDetailsCard(theme),
              const SizedBox(height: 250),
            ],
          ),
        ),
        _SubtleEntryAnimator(
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: centerCluster,
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'fab_announcements',
                  onPressed: _handleAnnouncements,
                  tooltip: 'Pengumuman',
                  child: const Icon(Icons.campaign_outlined),
                ),
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
              const SizedBox(height: 4.0),
              Text(
                _user!['name'] as String? ?? 'Pengguna',
                style: theme.textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeotagControlCard(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(179),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.colorScheme.onSurface.withAlpha(26),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Presensi', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      _isActive ? 'Presensi diaktifkan' : 'Aktifkan untuk melapor',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _isActive,
                onChanged: _isFetchingLocation ? null : _toggleActive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceDetailsCard(ThemeData theme) {
    final validSelectedLocation = (_locationOptions.isNotEmpty && _locationOptions.contains(_selectedLocation))
        ? _selectedLocation
        : (_locationOptions.isNotEmpty ? _locationOptions[0] : null);

    final bool isInteractable = _isActive && !_isFetchingLocation;
    final bool isEffectivelyAvailable = isInteractable && (_user!['status'] == 1);
    final bool hasStoredNotes = _storedNotes != null && _storedNotes!.isNotEmpty && _storedNotes != '-';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isActive)
          _SubtleEntryAnimator(
            duration: const Duration(milliseconds: 500),
            child: IgnorePointer(
              ignoring: !isInteractable,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isInteractable ? 1.0 : 0.5,
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Icon(
                      isEffectivelyAvailable ? Icons.check_circle_outline : Icons.highlight_off_outlined,
                      color: isEffectivelyAvailable ? theme.extension<CustomColors>()?.success : theme.colorScheme.error,
                      size: 28,
                    ),
                    title: const Text('Status'),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: isEffectivelyAvailable
                              ? theme.extension<CustomColors>()?.success
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEffectivelyAvailable ? 'Available' : 'Unavailable',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: _updatingStatus
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : Switch(
                      value: isEffectivelyAvailable,
                      onChanged: isInteractable ? _updateStatus : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16.0),
        if (_isActive)
          _SubtleEntryAnimator(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 100),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Lokasi', style: theme.textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Ambil Ulang Lokasi',
                          onPressed: isInteractable ? _fetchLocationData : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        mapContent,
                        if (isInteractable)
                          Positioned(
                            top: 10,
                            left: 12,
                            right: 12,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: DropdownButtonFormField<String>(
                                value: validSelectedLocation,
                                items: _locationOptions.map((loc) => DropdownMenuItem<String>(value: loc, child: Text(loc, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() => _selectedLocation = val),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.colorScheme.surface.withAlpha(240),
                                  hintText: 'Pilih Lokasi Terdekat',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      onExpansionChanged: (isExpanding) {
                        if (isExpanding) {
                          _notesFocusNode.requestFocus();
                        } else {
                          _notesFocusNode.unfocus();
                        }
                      },
                      enabled: isInteractable,
                      leading: const Icon(Icons.note_alt_outlined),
                      title: const Text('Catatan Tambahan'),
                      subtitle: _notesController.text.isNotEmpty
                          ? Text(
                        _notesController.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      )
                          : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: TextField(
                            focusNode: _notesFocusNode,
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'Tulis catatan Anda di sini...',
                              suffixIcon: hasStoredNotes
                                  ? IconButton(
                                icon: const Icon(Icons.history_rounded),
                                tooltip: 'Gunakan catatan sebelumnya',
                                onPressed: isInteractable
                                    ? () {
                                  setState(() {
                                    _notesController.text = _storedNotes!;
                                  });
                                }
                                    : null,
                              )
                                  : null,
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubtleEntryAnimator extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const _SubtleEntryAnimator({
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<_SubtleEntryAnimator> createState() => _SubtleEntryAnimatorState();
}

class _SubtleEntryAnimatorState extends State<_SubtleEntryAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}