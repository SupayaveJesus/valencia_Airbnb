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
  ///
  /// En otras palabras: este provider es el dueño del estado de autenticación
  /// dentro del árbol de widgets. Las pantallas leen getters; el provider decide
  /// cuándo una operación empezó, terminó, falló o dejó una sesión vigente.
  UserSession? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  /// Getters públicos = contrato de lectura para la UI.
  ///
  /// La interfaz reacciona a estos valores sin conocer detalles del HTTP ni del
  /// parseo. Así el feedback de UX queda centralizado y consistente.
  UserSession? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser?.isAuthenticatedSession ?? false;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Un login solo es exitoso si termina en una sesión realmente utilizable.
  ///
  /// `AuthService.login()` decide si la respuesta identifica al cliente. Si la
  /// sesión sirve, este provider publica el usuario y la app puede abrir Home.
  /// Si no sirve, publica error para que la UI mantenga el flujo en Login.
  Future<bool> login({required String email, required String password}) async {
    _startRequest();

    try {
      // La secuencia UI -> provider -> service termina acá cuando el service ya
      // devolvió una sesión lista para que el resto de la app reaccione.
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
  /// - éxito autenticado, para continuar dentro de la app;
  /// - éxito sin sesión, para volver a login con mensaje claro;
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

      // `result.session` puede ser null cuando la cuenta se creó correctamente,
      // pero la API espera que la persona inicie sesión en el siguiente paso.
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
    // Logout limpia TODO el estado observable ligado a autenticación para que la
    // UI y los providers dependientes vuelvan a un estado neutro y predecible.
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
    // Encendemos loading y limpiamos mensajes viejos antes de hablar con la red
    // para que la UX no mezcle feedback actual con respuestas anteriores.
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    // El `finally` de login/register siempre termina acá, incluso con error.
    // Eso garantiza que el spinner no quede prendido por una excepción.
    _isLoading = false;
    notifyListeners();
  }
}
