import 'package:flutter_test/flutter_test.dart';
import 'package:practico_final/models/registration_result.dart';
import 'package:practico_final/models/user_session.dart';
import 'package:practico_final/providers/auth_provider.dart';
import 'package:practico_final/services/auth_service.dart';

void main() {
  group('Contrato real de autenticación', () {
    test('acepta una sesión identificable aunque no traiga token', () {
      final session = UserSession.fromJson({
        'id': 7,
        'nombrecompleto': 'Cliente Real',
        'email': 'cliente@real.com',
        'telefono': '7777777',
      });

      // El backend actual puede autenticar por identidad de usuario sin emitir
      // token. Si esto cambia, login y estado de sesión quedarían mal evaluados.
      expect(session.hasToken, isFalse);
      expect(session.isAuthenticatedSession, isTrue);
      expect(session.hasIdentifier, isTrue);
    });

    test('AuthProvider considera autenticado un login sin token', () async {
      final provider = AuthProvider(authService: _AuthServiceStub());

      final success = await provider.login(
        email: 'cliente@real.com',
        password: 'password',
      );

      // Esta secuencia protege el flujo real de entrada: provider exitoso,
      // sesión disponible y datos mínimos suficientes para navegar.
      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.hasToken, isFalse);
      expect(provider.currentUser?.email, 'cliente@real.com');
    });
  });
}

class _AuthServiceStub extends AuthService {
  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    return UserSession(
      id: 42,
      email: email,
      fullName: 'Cliente API real',
      phone: '7000000',
      token: '',
      rawData: const {},
    );
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    throw UnimplementedError();
  }
}
