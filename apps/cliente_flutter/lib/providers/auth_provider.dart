import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  /// Provider = estado observable para la UI.
  ///
  /// La pantalla no toca Dio directo; solo observa loading, usuario y errores.
  UserSession? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserSession? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String password}) async {
    _startRequest();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _finishRequest();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _startRequest();

    try {
      _currentUser = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _finishRequest();
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startRequest() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    notifyListeners();
  }
}
