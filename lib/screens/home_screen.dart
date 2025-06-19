import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../services/profile_service.dart';
import '../services/permission_service.dart';
import '../models/geotag_response.dart';
import '../models/profile_response.dart';
import '../providers/theme_notifier.dart';
import '../theme/custom_colors.dart';
import '../widgets/map_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey _notesExpansionTileKey = GlobalKey();
  DateTime? _lastBackPressed;
  Map<String, dynamic>? _user;
  bool _isActive = false;
  bool _isFetchingLocation = false;
  bool _updatingStatus = false;
  bool _isSaving = false;
  List<String> _locationOptions = [];
  String? _selectedLocation;
  LatLng? _currentLatLng;
  final TextEditingController _notesController = TextEditingController();
  String? _storedNotes;
  final FocusNode _notesFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final service = FlutterBackgroundService();
  final ExpansibleController _notesExpansionController = ExpansibleController();
  bool _isNotesExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndSyncOnStartup();
    _notesFocusNode.addListener(_onFocusChange);
  }

  void _executeScroll() {
    if (!mounted) return;
    final context = _notesExpansionTileKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.4,
      );
    }
  }

  void _onFocusChange() {
    if (!_notesFocusNode.hasFocus) return;
    _notesExpansionController.expand();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _executeScroll();
      }
    });
  }

  Future<void> _loadAndSyncOnStartup() async {
    await _loadUser();
    if (mounted && _isActive && _currentLatLng == null) {
      _fetchLocationData(isNewActivation: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesController.dispose();
    _notesFocusNode.removeListener(_onFocusChange);
    _notesFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserStorage.getUser();
    if (!mounted) return;
    final isServiceRunning = await service.isRunning();
    setState(() {
      _user = user;
      _isActive = isServiceRunning;
      final lat = user['lat'] as double?;
      final long = user['long'] as double?;
      if (lat != null && long != null) {
        _currentLatLng = LatLng(lat, long);
      }
      final options = user['location_options'] as List?;
      if (options != null) {
        _locationOptions = List<String>.from(options);
      }
      _selectedLocation = user['geotag'] as String?;
      _storedNotes = user['notes'] as String?;
      if (_storedNotes != null && _storedNotes != '-') {
        _notesController.text = _storedNotes!;
      } else {
        _notesController.clear();
      }
    });
  }

  Future<void> _toggleActive(bool value) async {
    if (value) {
      final bool permissionGranted = await PermissionService.handleLocationPermission(context);
      if (!mounted || !permissionGranted) {
        return;
      }
      setState(() => _isActive = true);
      _fetchLocationData(isNewActivation: true);
    } else {
      _showConfirmationDialog(
        title: 'Nonaktifkan Presensi?',
        content: 'Layanan di latar belakang akan dihentikan dan status Anda menjadi "Unavailable". Lanjutkan?',
        onConfirm: () async {
          final updatedUser = Map<String, dynamic>.from(_user!)
            ..['geotag'] = '-'
            ..['status'] = 0
            ..remove('lat')
            ..remove('long')
            ..remove('location_options');
          await UserStorage.saveUser(updatedUser);
          try {
            await ProfileService.updateUserProfile();
          } catch (e) {
            debugPrint("Gagal menyinkronkan status nonaktif: $e");
          }
          if (!mounted) return;
          setState(() {
            _isActive = false;
            _locationOptions = [];
            _selectedLocation = null;
            _currentLatLng = null;
            _user = updatedUser;
          });
        },
      );
    }
  }

  Future<void> _fetchLocationData({bool isNewActivation = false}) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isFetchingLocation = true);
    try {
      final GeotagResponse result = await GeotagService.fetchGeotagData();
      if (!mounted) return;

      if (result.success && result.lat != null && result.long != null && (result.locationLists?.isNotEmpty ?? false)) {
        final uniqueLocations = result.locationLists!.toSet().toList();

        final currentStatus = _user?['status'] as int? ?? 0;
        final newStatus = isNewActivation ? 0 : currentStatus;

        final updatedUser = Map<String, dynamic>.from(_user!)
          ..['geotag'] = uniqueLocations[0]
          ..['status'] = newStatus
          ..['lat'] = result.lat
          ..['long'] = result.long
          ..['location_options'] = uniqueLocations;

        await UserStorage.saveUser(updatedUser);

        ProfileService.updateUserProfile().catchError((error) {
          debugPrint("Pembaruan profil di latar belakang gagal: $error");
          return UpdateProfileResponse(success: false, message: 'Background update failed');
        });

        setState(() {
          _user = updatedUser;
          _currentLatLng = LatLng(result.lat!, result.long!);
          _locationOptions = uniqueLocations;
          _selectedLocation = uniqueLocations[0];
        });

      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message ?? '❌ Gagal mendapatkan lokasi.')));
        if(mounted) setState(() => _isActive = false);
      }
    } catch (e) {
      if(mounted) messenger.showSnackBar(SnackBar(content: Text('❌ Terjadi error: ${e.toString()}')));
      if(mounted) setState(() => _isActive = false);
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

    if (mounted) {
      setState(() {
        _user = updatedUser;
        _updatingStatus = false;
      });
    }

    ProfileService.updateUserProfile().catchError((error) {
      debugPrint("Gagal sinkronisasi status (Available/Unavailable): $error");
      return UpdateProfileResponse(success: false, message: 'Status sync failed');
    });
  }

  void _saveData() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (_notesExpansionController.isExpanded) {
      _notesExpansionController.collapse();
    }
    setState(() => _isSaving = true);
    try {
      if (_user == null) return;

      final messenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);

      final currentNotes = _notesController.text.trim();
      final currentSelectedLocation = _selectedLocation ?? (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : '-');

      final updatedUser = Map<String, dynamic>.from(_user!)
        ..['notes'] = currentNotes.isEmpty ? '-' : currentNotes
        ..['geotag'] = currentSelectedLocation;

      await UserStorage.saveUser(updatedUser);
      if (!mounted) return;

      final UpdateProfileResponse result = await ProfileService.updateUserProfile();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.success ? (result.message ?? '✅ Profil berhasil diperbarui.') : (result.message ?? '❌ Gagal memperbarui profil.')),
          backgroundColor: result.success ? theme.extension<CustomColors>()?.success : theme.colorScheme.errorContainer,
        ),
      );

      if (result.success) await _loadUser();

    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark ||
        (theme.brightness == Brightness.dark && themeNotifier.themeMode == ThemeMode.system);

    Color appBarColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : theme.colorScheme.primary;
    Color onAppBarColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 1,
          shadowColor: Colors.black.withAlpha(50),
          automaticallyImplyLeading: false,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: onAppBarColor.withAlpha(20),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/unnes_logo.jpg',
                  height: 28,
                  errorBuilder: (c, e, s) => Icon(Icons.school, size: 28, color: onAppBarColor),
                ),
                const SizedBox(width: 12),
                Text('Doswall', style: theme.textTheme.headlineSmall?.copyWith(
                  color: onAppBarColor,
                )),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(isEffectivelyDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: isEffectivelyDark ? 'Mode Terang' : 'Mode Gelap',
              onPressed: () => themeNotifier.toggleTheme(isEffectivelyDark ? Brightness.dark : Brightness.light),
              color: onAppBarColor,
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Buka Profil',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              color: onAppBarColor,
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildArtisticBackground(context, isEffectivelyDark),
            _buildPresenceTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildArtisticBackground(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -180,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withAlpha(isDark ? 30 : 50),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: secondary.withAlpha(isDark ? 35 : 55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresenceTab(BuildContext context) {
    final theme = Theme.of(context);
    bool isAdminOrSuperAdmin = _user!['role'] == 'admin' || _user!['role'] == 'superadmin';

    Widget saveButton = AnimatedScale(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      scale: (_isActive || _isNotesExpanded) ? 1.0 : 0.0,
      child: FloatingActionButton.extended(
        heroTag: 'fab_save',
        onPressed: _isFetchingLocation || _isSaving ? null : _saveData,
        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
        icon: _isFetchingLocation || _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_alt_outlined),
      ),
    );

    Widget? adminButton;
    if (isAdminOrSuperAdmin) {
      adminButton = AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
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

    Widget centerCluster = (adminButton != null && _isActive)
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        adminButton,
        const SizedBox(width: 12),
        saveButton,
        const SizedBox(width: 12),
        const SizedBox(width: 56),
      ],
    )
        : (adminButton ?? saveButton);


    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserProfileHeader(theme),
              const SizedBox(height: 24.0),
              _buildGeotagControlCard(theme),
              const SizedBox(height: 16.0),
              _buildPresenceDetailsCard(theme),
              const SizedBox(height: 100),
            ],
          ),
        ),
        Stack(
          children: [
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Align(alignment: Alignment.bottomCenter, child: centerCluster),
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
      ],
    );
  }

  Widget _buildUserProfileHeader(ThemeData theme) {
    if (_user == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat Datang,', style: theme.textTheme.bodyLarge),
          Text(
            _user!['name'] as String? ?? 'Pengguna',
            style: theme.textTheme.headlineLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGeotagControlCard(ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    _isActive ? 'Layanan presensi diaktifkan' : 'Aktifkan untuk melapor kehadiran',
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
    );
  }

  Widget _buildPresenceDetailsCard(ThemeData theme) {
    if (_isActive) {
      if (_currentLatLng == null) {
        return const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _SubtleEntryAnimator(
        duration: const Duration(milliseconds: 500),
        delay: const Duration(milliseconds: 150),
        child: Column(
          children: [
            _buildStatusTile(theme),
            const SizedBox(height: 16),
            MapCard(
              currentLatLng: _currentLatLng,
              locationOptions: _locationOptions,
              selectedLocation: _selectedLocation,
              isFetchingLocation: _isFetchingLocation,
              isInteractable: _isActive && !_isFetchingLocation,
              onRefresh: () => _fetchLocationData(isNewActivation: false),
              onLocationChanged: (val) => setState(() => _selectedLocation = val),
            ),
            const SizedBox(height: 16),
            _buildNotesCard(theme),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          _buildNotesCard(theme),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Aktifkan presensi untuk mendapatkan data lokasi.",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatusTile(ThemeData theme) {
    final bool isInteractable = _isActive && !_isFetchingLocation;
    final bool isEffectivelyAvailable = _user?['status'] == 1;
    final color = isEffectivelyAvailable
        ? (theme.extension<CustomColors>()?.success ?? Colors.green)
        : theme.colorScheme.error;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          isEffectivelyAvailable ? Icons.check_circle_outline : Icons.highlight_off_outlined,
          color: color,
          size: 28,
        ),
        title: const Text('Status Ketersediaan'),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 6),
            Text(isEffectivelyAvailable ? 'Available' : 'Unavailable'),
          ],
        ),
        trailing: _updatingStatus
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
            : Switch(
          value: isEffectivelyAvailable,
          onChanged: isInteractable ? _updateStatus : null,
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    final bool isNotesInteractable = !_isSaving;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: _notesExpansionTileKey,
          controller: _notesExpansionController,
          onExpansionChanged: (isExpanding) {
            setState(() {
              _isNotesExpanded = isExpanding;
            });
            if (!isNotesInteractable) return;
            if (isExpanding) {
              _notesFocusNode.requestFocus();
            } else {
              _notesFocusNode.unfocus();
            }
          },
          enabled: isNotesInteractable,
          leading: const Icon(Icons.note_alt_outlined),
          title: const Text('Catatan Tambahan'),
          subtitle: _notesController.text.isNotEmpty
              ? Text(_notesController.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)
              : const Text('Ketuk untuk menambahkan catatan'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: TextField(
                focusNode: _notesFocusNode,
                controller: _notesController,
                enabled: isNotesInteractable,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan Anda di sini...',
                  suffixIcon: _storedNotes != null && _storedNotes!.isNotEmpty && _storedNotes != '-'
                      ? IconButton(
                    icon: const Icon(Icons.history_rounded),
                    tooltip: 'Gunakan catatan sebelumnya',
                    onPressed: isNotesInteractable ? () => setState(() => _notesController.text = _storedNotes!) : null,
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