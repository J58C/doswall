import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class SplashViewModel with ChangeNotifier {
  Future<void> initializeApp({
    required Function(AuthResult authResult) onComplete,
  }) async {
    await Future.delayed(const Duration(seconds: 1000));
    final authResult = await AuthService.checkAuthentication();
    onComplete(authResult);
  }
}