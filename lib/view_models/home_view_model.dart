import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:latlong2/latlong.dart';

import '../services/user_storage.dart';
import '../services/geotag_service.dart';
import '../services/profile_service.dart';
import '../services/admin_redirect_service.dart';
import '../models/geotag_response.dart';
import '../models/profile_response.dart';

class HomeViewModel extends ChangeNotifier {
  final _backgroundService = FlutterBackgroundService();

  Map<String, dynamic>? _user;
  bool _isActive = false;
  bool _isFetchingLocation = false;
  bool _updatingStatus = false;
  bool _isSaving = false;
  List<String> _locationOptions = [];
  String? _selectedLocation;
  LatLng? _currentLatLng;
  String? _storedNotes;
  bool _isNotesExpanded = false;
  String? _errorMessage;
  String? _successMessage;

  Map<String, dynamic>? get user => _user;
  bool get isActive => _isActive;
  bool get isFetchingLocation => _isFetchingLocation;
  bool get updatingStatus => _updatingStatus;
  bool get isSaving => _isSaving;
  List<String> get locationOptions => _locationOptions;
  String? get selectedLocation => _selectedLocation;
  LatLng? get currentLatLng => _currentLatLng;
  String? get storedNotes => _storedNotes;
  bool get isNotesExpanded => _isNotesExpanded;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  final TextEditingController notesController = TextEditingController();

  HomeViewModel() {
    loadAndSyncOnStartup();
    _backgroundService.on('stopped').listen((_) {
      if (_isActive) {
        debugPrint("Service berhenti di hentikan");
        _isActive = false;
        _locationOptions = [];
        _selectedLocation = null;
        _currentLatLng = null;
        notifyListeners();
      }
    });
  }

  void clearAllStateForLogout() {
    _user = null;
    _isActive = false;
    _isFetchingLocation = false;
    _updatingStatus = false;
    _isSaving = false;
    _locationOptions = [];
    _selectedLocation = null;
    _currentLatLng = null;
    _storedNotes = null;
    _isNotesExpanded = false;
    notesController.clear();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  set isNotesExpanded(bool value) {
    _isNotesExpanded = value;
    notifyListeners();
  }

  void onLocationChanged(String? value) {
    _selectedLocation = value;
    notifyListeners();
  }

  Future<void> loadAndSyncOnStartup() async {
    final serviceIsRunning = await _backgroundService.isRunning();
    final user = await UserStorage.getUser();
    if (user.isEmpty) {
      if (serviceIsRunning) {
        _backgroundService.invoke('stopService');
      }
      clearAllStateForLogout();
      return;
    }

    _user = user;
    _isActive = serviceIsRunning;

    if (_isActive) {
      final lat = user['lat'] as double?;
      final long = user['long'] as double?;
      if (lat != null && long != null) {
        _currentLatLng = LatLng(lat, long);
      }
      final options = user['location_options'] as List?;
      _locationOptions = options?.map((e) => e.toString()).toList() ?? [];
      _selectedLocation = user['geotag'] as String?;
    } else {
      _currentLatLng = null;
      _locationOptions = [];
      _selectedLocation = null;
    }

    _storedNotes = user['notes'] as String?;
    if (_storedNotes != null && _storedNotes != '-') {
      notesController.text = _storedNotes!;
    } else {
      notesController.clear();
    }

    notifyListeners();
  }

  Future<void> toggleActive(bool value) async {
    if (value) {
      await _backgroundService.startService();

      _isActive = true;
      notifyListeners();
      await fetchLocationData(isNewActivation: true);
    }
  }

  Future<void> deactivatePresence() async {
    if (_user == null) return;

    final updatedUser = Map<String, dynamic>.from(_user!)
      ..['geotag'] = '-'
      ..['status'] = 0
      ..remove('lat')
      ..remove('long')
      ..remove('location_options');

    await UserStorage.saveUser(updatedUser);

    ProfileService.updateUserProfile().catchError((error) {
      debugPrint("Sinkronisasi status nonaktif gagal: $error");
      return UpdateProfileResponse(success: false, message: 'Deactivation sync failed');
    });

    _isActive = false;
    _locationOptions = [];
    _selectedLocation = null;
    _currentLatLng = null;
    _user = updatedUser;

    if (await _backgroundService.isRunning()) {
      _backgroundService.invoke('stop_service');
    }

    notifyListeners();
  }

  Future<void> fetchLocationData({bool isNewActivation = false}) async {
    if (_user == null) return;

    _isFetchingLocation = true;
    notifyListeners();

    try {
      final GeotagResponse result = await GeotagService.fetchGeotagData();
      if (result.success && result.lat != null && result.long != null && (result.locationLists?.isNotEmpty ?? false)) {
        final uniqueLocations = result.locationLists!.toSet().toList();
        final currentStatus = _user!['status'] as int? ?? 0;
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

        _user = updatedUser;
        _currentLatLng = LatLng(result.lat!, result.long!);
        _locationOptions = uniqueLocations;
        _selectedLocation = uniqueLocations[0];
        _isActive = true;
      } else {
        _errorMessage = result.message ?? '❌ Gagal mendapatkan lokasi.';
        _isActive = false;
      }
    } catch (e) {
      _errorMessage = '❌ Terjadi error: ${e.toString()}';
      _isActive = false;
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(bool value) async {
    if (_user == null) return;

    _updatingStatus = true;
    notifyListeners();

    final updatedUser = Map<String, dynamic>.from(_user!)..['status'] = value ? 1 : 0;
    await UserStorage.saveUser(updatedUser);

    _user = updatedUser;
    _updatingStatus = false;
    notifyListeners();

    ProfileService.updateUserProfile().catchError((error) {
      debugPrint("Gagal sinkronisasi status: $error");
      return UpdateProfileResponse(success: false, message: 'Status sync failed');
    });
  }

  Future<void> saveData() async {
    if (_user == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final currentNotes = notesController.text.trim();
      final currentSelectedLocation = _selectedLocation ?? (_isActive && _locationOptions.isNotEmpty ? _locationOptions[0] : '-');

      final updatedUser = Map<String, dynamic>.from(_user!)
        ..['notes'] = currentNotes.isEmpty ? '-' : currentNotes
        ..['geotag'] = currentSelectedLocation;

      await UserStorage.saveUser(updatedUser);

      final UpdateProfileResponse result = await ProfileService.updateUserProfile();

      if (result.success) {
        _successMessage = result.message ?? '✅ Profil berhasil diperbarui.';
        await loadAndSyncOnStartup();
      } else {
        _errorMessage = result.message ?? '❌ Gagal memperbarui profil.';
      }
    } catch (e) {
      _errorMessage = '❌ Terjadi error saat menyimpan: ${e.toString()}';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleAdminAction() async {
    try {
      await AdminRedirectService.launchAdminPanel();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}