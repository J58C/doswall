import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import '../services/user_storage.dart';
import '../enums/view_state.dart';

class LoginViewModel with ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
    required VoidCallback onSuccess,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = '';

    try {
      final AuthResponse result = await AuthService.login(email, password);

      if (result.success && result.userData != null) {
        await UserStorage.saveUser(result.userData!);
        _setState(ViewState.success);
        onSuccess();
      } else {
        _errorMessage = result.message ?? 'Email atau password salah.';
        _setState(ViewState.error);
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server.';
      _setState(ViewState.error);
    }
  }

  void resetState() {
    if (_state == ViewState.error) {
      _setState(ViewState.idle);
    }
  }
}