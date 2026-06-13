import '../models/registration_result.dart';
import '../models/user_session.dart';
import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Flujo real de login:
  /// 1. prueba las rutas candidatas conocidas de la API;
  /// 2. normaliza la respuesta a un `Map<String, dynamic>`;
  /// 3. intenta construir una `UserSession` tolerante a distintas formas JSON;
  /// 4. valida que exista identidad usable para que la UI sepa si abre Home.
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postToCandidates(
      paths: const ['/api/users/login', '/cliente/login', '/api/cliente/login'],
      body: {'email': email.trim(), 'password': password},
    );

    // `response.data` puede venir como `Map`, `Map<String, dynamic>` o en una
    // forma no útil. Primero lo llevamos a un contrato consistente.
    final data = _normalizeMap(response.data);
    final session = UserSession.fromJson(data);

    // HTTP 2xx NO alcanza por sí solo: necesitamos identidad usable del cliente
    // (id y/o email) para afirmar que la sesión sirve. Esta regla vive en el
    // service porque pertenece al contrato con la API, no a la pantalla.
    if (!session.isAuthenticatedSession) {
      throw Exception(_extractLoginFailureMessage(data));
    }

    return session;
  }

  /// Intenta registrar un cliente usando exactamente los campos confirmados por
  /// la API.
  ///
  /// El resultado distingue dos casos válidos para la UX:
  /// - cuenta creada y sesión abierta en la misma respuesta;
  /// - cuenta creada sin sesión, para volver a login con mensaje claro.
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    // El payload usa los nombres exactos que espera la API (`nombrecompleto` y
    // `telefono`). Esta traducción pertenece al service porque es contrato HTTP.
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

    // No mezclamos "cuenta creada" con "sesión abierta". Solo tratamos el
    // registro como autenticado cuando la respuesta trae token explícito.
    if (session.hasToken) {
      return RegistrationResult.authenticated(session);
    }

    return RegistrationResult.successWithoutSession(
      message: _extractRegisterSuccessMessage(data),
    );
  }

  Map<String, dynamic> _normalizeMap(Object? rawData) {
    // La capa superior quiere parsear JSON, no adivinar tipos. Este helper deja
    // claro que el service absorbe la variabilidad de `response.data`.
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
  /// persona usuaria: la cuenta existe y ahora debe iniciar sesión.
  String _extractRegisterSuccessMessage(Map<String, dynamic> data) {
    final backendMessage = _readString(data['message'] ?? data['mensaje']);

    if (backendMessage.isNotEmpty) {
      return '$backendMessage Ahora iniciá sesión.';
    }

    return 'Registro exitoso, ahora iniciá sesión.';
  }

  /// Cuando login responde 2xx pero sin identidad usable, el problema NO es de
  /// red: la API no confirmó qué cliente quedó autenticado.
  ///
  /// Por eso devolvemos un mensaje pedagógico y accionable para la UI.
  String _extractLoginFailureMessage(Map<String, dynamic> data) {
    final backendMessage = _readString(data['message'] ?? data['mensaje']);

    if (backendMessage.isNotEmpty) {
      return '$backendMessage No se pudo abrir una sesión válida.';
    }

    return 'No se pudo iniciar sesión porque el servidor no devolvió un cliente identificable.';
  }

  String _readString(Object? value) {
    return value == null ? '' : '$value'.trim();
  }
}
