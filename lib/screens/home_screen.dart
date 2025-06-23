import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/home_view_model.dart';
import '../services/permission_service.dart';

import '../models/background_shape.dart';
import '../widgets/artistic_background.dart';
import '../widgets/header_card.dart';
import '../widgets/presence_details_card.dart';
import '../widgets/notes_card.dart';
import '../widgets/app_floating_action_button.dart';
import '../providers/theme_notifier.dart';
import '../theme/custom_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey _notesExpansionTileKey = GlobalKey();
  final FocusNode _notesFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ExpansibleController _notesExpansionController = ExpansibleController();
  DateTime? _lastBackPressed;

  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notesFocusNode.addListener(_onFocusChange);

    _viewModel = Provider.of<HomeViewModel>(context, listen: false);
    _viewModel.loadAndSyncOnStartup();
    _viewModel.addListener(_showMessages);
  }

  void _showMessages() {
    if (!mounted) return;
    final theme = Theme.of(context);

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } else if (_viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage!),
          backgroundColor: theme.extension<CustomColors>()?.success,
        ),
      );
    }
    _viewModel.clearMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_showMessages);
    _notesFocusNode.removeListener(_onFocusChange);
    _notesFocusNode.dispose();
    _scrollController.dispose();
    _notesExpansionController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_notesFocusNode.hasFocus) return;
    _notesExpansionController.expand();
    void scrollAction() {
      if (!mounted) {
        return;
      }
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
    Future.delayed(const Duration(milliseconds: 400), scrollAction);
  }

  Future<void> _handleToggle(bool value, HomeViewModel viewModel) async {
    if (value) {
      final notifPermissionResult = await NotificationPermissionHandler.handle();
      if (notifPermissionResult != NotificationPermissionResult.granted) {
        if (mounted) {
          final errorMessage = NotificationPermissionHandler.getErrorMessage(notifPermissionResult);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
        return;
      }
      final locationPermissionResult = await LocationPermissionHandler.handle();
      if (locationPermissionResult != LocationPermissionResult.granted) {
        if (mounted) {
          final errorMessage = LocationPermissionHandler.getErrorMessage(locationPermissionResult);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
        return;
      }
      viewModel.toggleActive(true);
    } else {
      _showConfirmationDialog(
        title: 'Nonaktifkan Presensi?',
        content:
        'Layanan di latar belakang akan dihentikan dan status Anda menjadi "Unavailable". Lanjutkan?',
        onConfirm: () => viewModel.deactivatePresence(),
      );
    }
  }

  void _saveData(HomeViewModel viewModel) {
    FocusScope.of(context).unfocus();
    if (_notesExpansionController.isExpanded) {
      _notesExpansionController.collapse();
    }
    viewModel.saveData();
  }

  void _showConfirmationDialog({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isEffectivelyDark = themeNotifier.themeMode == ThemeMode.dark || (theme.brightness == Brightness.dark && themeNotifier.themeMode == ThemeMode.system);
    final Color appBarColor = isEffectivelyDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    final Color onAppBarColor = isEffectivelyDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    final List<BackgroundShape> homeScreenPattern = [
      BackgroundShape(top: -120, left: -180, width: 350, height: 350, color: theme.colorScheme.primary.withAlpha(isEffectivelyDark ? 30 : 50)),
      BackgroundShape(bottom: -150, right: -100, width: 320, height: 320, color: theme.colorScheme.secondary.withAlpha(isEffectivelyDark ? 35 : 55)),
    ];
    final bool isAdmin = viewModel.user!['role'] == 'admin' || viewModel.user!['role'] == 'superadmin';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null || now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tekan sekali lagi untuk keluar'), duration: Duration(seconds: 2)));
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
            decoration: BoxDecoration(color: onAppBarColor.withAlpha(20), borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/unnes_logo.jpg', height: 28, errorBuilder: (c, e, s) => Icon(Icons.school, size: 28, color: onAppBarColor)),
                const SizedBox(width: 12),
                Text('Doswall', style: theme.textTheme.headlineSmall?.copyWith(color: onAppBarColor)),
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
            ArtisticBackground(shapes: homeScreenPattern),
            _buildPresenceTab(context, viewModel),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppFloatingActionButton.home(
          viewModel: viewModel,
          isAdmin: isAdmin,
          onAnnouncementsAction: () => Navigator.pushNamed(context, '/announcements'),
          onSaveData: () => _saveData(viewModel),
          onAdminAction: viewModel.handleAdminAction,
        ),
      ),
    );
  }

  Widget _buildPresenceTab(BuildContext context, HomeViewModel viewModel) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderCard(
            user: viewModel.user,
            isActive: viewModel.isActive,
            isFetchingLocation: viewModel.isFetchingLocation,
            onToggle: (value) => _handleToggle(value, viewModel),
          ),
          const SizedBox(height: 16.0),
          PresenceDetailsCard(
            isActive: viewModel.isActive,
            isFetchingLocation: viewModel.isFetchingLocation,
            updatingStatus: viewModel.updatingStatus,
            currentLatLng: viewModel.currentLatLng,
            locationOptions: viewModel.locationOptions,
            selectedLocation: viewModel.selectedLocation,
            user: viewModel.user,
            onLocationChanged: viewModel.onLocationChanged,
            onRefresh: () => viewModel.fetchLocationData(isNewActivation: false),
            updateStatus: viewModel.updateStatus,
          ),
          const SizedBox(height: 16.0),
          NotesCard(
            isSaving: viewModel.isSaving,
            notesController: viewModel.notesController,
            storedNotes: viewModel.storedNotes,
            notesExpansionTileKey: _notesExpansionTileKey,
            notesExpansionController: _notesExpansionController,
            notesFocusNode: _notesFocusNode,
            onExpansionChanged: (isExpanding) {
              viewModel.isNotesExpanded = isExpanding;
              if (isExpanding) {
                _notesFocusNode.requestFocus();
              } else {
                _notesFocusNode.unfocus();
              }
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}