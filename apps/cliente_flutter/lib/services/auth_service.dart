import '../models/user_session.dart';
import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postToCandidates(
      paths: const [
        '/api/users/login',
        '/cliente/login',
        '/api/cliente/login',
      ],
      body: {'email': email.trim(), 'password': password},
    );

    final data = _normalizeMap(response.data);
    return UserSession.fromJson(data);
  }

  Future<UserSession> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
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
    if ((data['token'] ?? data['access_token']) == null) {
      return login(email: email, password: password);
    }

    return UserSession.fromJson(data);
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
}
