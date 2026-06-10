import '../models/registration_result.dart';
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
  String? _successMessage;

  UserSession? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser?.hasToken ?? false;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Un login solo es exitoso si termina en una sesión realmente autenticada.
  ///
  /// La validación fuerte vive en `AuthService.login()`: si el backend responde
  /// 2xx pero omite el token, el servicio lanza una excepción y la UI muestra
  /// el mensaje como fallo de autenticación, no como éxito parcial.
  Future<bool> login({required String email, required String password}) async {
    _startRequest();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      _errorMessage = null;
      _successMessage = null;
      return true;
    } catch (error) {
      _currentUser = null;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _finishRequest();
    }
  }

  /// Ejecuta el registro y traduce el resultado técnico a estado observable.
  ///
  /// La UI necesita distinguir entre:
  /// - éxito autenticado (entra a Home);
  /// - éxito sin sesión (vuelve al login con mensaje pedagógico);
  /// - error real del backend.
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _startRequest();

    try {
      final result = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );

      _currentUser = result.session;
      _errorMessage = null;
      _successMessage = result.message;
      return result;
    } catch (error) {
      _currentUser = null;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _successMessage = null;
      return RegistrationResult.failure();
    } finally {
      _finishRequest();
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void _startRequest() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    notifyListeners();
  }
}
