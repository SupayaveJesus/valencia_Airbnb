import 'user_session.dart';

/// Resultado del registro de cliente.
///
/// Esta clase existe para modelar DOS escenarios válidos del backend:
/// 1. registro exitoso + sesión autenticada inmediata;
/// 2. registro exitoso sin token, donde la app debe pedir login manual.
///
/// Separar estos casos evita un error conceptual importante: confundir
/// "no vino token" con "el registro falló".
class RegistrationResult {
  const RegistrationResult._({
    required this.isSuccess,
    required this.session,
    required this.message,
  });

  /// Caso ideal: el backend devuelve una sesión utilizable y la app puede seguir.
  factory RegistrationResult.authenticated(UserSession session) {
    return RegistrationResult._(
      isSuccess: true,
      session: session,
      message: null,
    );
  }

  /// Caso también exitoso: la cuenta se creó, pero el backend NO abrió sesión.
  factory RegistrationResult.successWithoutSession({String? message}) {
    return RegistrationResult._(
      isSuccess: true,
      session: null,
      message: message ?? 'Registro exitoso, ahora iniciá sesión.',
    );
  }

  /// Fallo real del registro.
  factory RegistrationResult.failure() {
    return const RegistrationResult._(
      isSuccess: false,
      session: null,
      message: null,
    );
  }

  final bool isSuccess;
  final UserSession? session;
  final String? message;

  /// Indica si el flujo terminó con una sesión utilizable.
  bool get isAuthenticated => session?.isAuthenticatedSession ?? false;
}
