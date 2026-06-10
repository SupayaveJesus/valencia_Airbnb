import '../config/app_environment.dart';
import '../models/registration_result.dart';
import '../models/user_session.dart';
import 'api_client.dart';
import 'mock/mock_cliente_data.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    if (AppEnvironment.useMockServices) {
      return MockClienteData.login(email: email, password: password);
    }

    final response = await _apiClient.postToCandidates(
      paths: const ['/api/users/login', '/cliente/login', '/api/cliente/login'],
      body: {'email': email.trim(), 'password': password},
    );

    final data = _normalizeMap(response.data);
    final session = UserSession.fromJson(data);

    // Endurecemos el contrato del login: HTTP 200 NO alcanza por sí solo.
    // Para que exista sesión real, el backend debe devolver un token usable.
    // Si no lo hace, preferimos fallar con un mensaje claro antes que dejar a
    // la UI en un falso "ingreso exitoso".
    if (!session.hasToken) {
      throw Exception(_extractLoginFailureMessage(data));
    }

    return session;
  }

  /// Intenta registrar un cliente usando exactamente los campos confirmados
  /// por el backend docente.
  ///
  /// Punto clave del bugfix:
  /// - si el backend devuelve token, seguimos con sesión autenticada;
  /// - si el backend crea la cuenta pero NO devuelve token, eso sigue siendo
  ///   un éxito funcional y NO debe transformarse en error artificial.
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    if (AppEnvironment.useMockServices) {
      return RegistrationResult.successWithoutSession(
        message: MockClienteData.register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone,
        ),
      );
    }

    final payload = {
      'nombrecompleto': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'telefono': phone.trim(),
    };

    final response = await _apiClient.postToCandidates(
      paths: const ['/cliente/registro', '/api/cliente/registro'],
      body: payload,
    );

    final data = _normalizeMap(response.data);
    final session = UserSession.fromJson(data);

    if (session.hasToken) {
      return RegistrationResult.authenticated(session);
    }

    return RegistrationResult.successWithoutSession(
      message: _extractRegisterSuccessMessage(data),
    );
  }

  Map<String, dynamic> _normalizeMap(Object? rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  /// Usa el mensaje del backend si aporta contexto útil.
  ///
  /// Si el servidor no envía nada claro, devolvemos una guía explícita para la
  /// persona usuaria: la cuenta se creó y ahora debe iniciar sesión.
  String _extractRegisterSuccessMessage(Map<String, dynamic> data) {
    final backendMessage = _readString(data['message'] ?? data['mensaje']);

    if (backendMessage.isNotEmpty) {
      return '$backendMessage Ahora iniciá sesión.';
    }

    return 'Registro exitoso, ahora iniciá sesión.';
  }

  /// Cuando login responde 2xx pero sin token, el problema NO es de red:
  /// el backend no confirmó una sesión autenticada completa.
  ///
  /// Por eso devolvemos un mensaje pedagógico y accionable para la UI.
  String _extractLoginFailureMessage(Map<String, dynamic> data) {
    final backendMessage = _readString(data['message'] ?? data['mensaje']);

    if (backendMessage.isNotEmpty) {
      return '$backendMessage No se pudo abrir una sesión válida.';
    }

    return 'No se pudo iniciar sesión porque el servidor no devolvió un token válido.';
  }

  String _readString(Object? value) {
    return value == null ? '' : '$value'.trim();
  }
}
