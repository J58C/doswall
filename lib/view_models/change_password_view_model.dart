import 'package:flutter/foundation.dart';
import '../services/password_service.dart';
import '../models/password_response.dart';
import '../enums/view_state.dart';

class ChangePasswordViewModel with ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required VoidCallback onSuccess,
    required Function(String message) onError,
  }) async {
    _setState(ViewState.loading);
    _errorMessage = '';

    try {
      final PasswordResponse result = await PasswordService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        _setState(ViewState.success);
        onSuccess();
      } else {
        _errorMessage = result.message ?? 'Gagal mengubah password.';
        _setState(ViewState.error);
        onError(_errorMessage);
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server.';
      _setState(ViewState.error);
      onError(_errorMessage);
    }
  }

  void resetState() {
    _setState(ViewState.idle);
  }
}