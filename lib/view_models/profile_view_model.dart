import 'package:flutter/foundation.dart';
import '../services/user_storage.dart';
import '../enums/view_state.dart';

class ProfileViewModel with ChangeNotifier {
  ViewState _state = ViewState.loading;
  Map<String, dynamic>? _user;
  String _errorMessage = '';

  ViewState get state => _state;
  Map<String, dynamic>? get user => _user;
  String get errorMessage => _errorMessage;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadUser() async {
    _setState(ViewState.loading);
    try {
      final userData = await UserStorage.getUser();
      _user = userData;
      _setState(ViewState.success);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _setState(ViewState.error);
    }
  }

  Future<void> logout() async {
    await UserStorage.clearUser();
    _user = null;
    _setState(ViewState.loading);
  }
}