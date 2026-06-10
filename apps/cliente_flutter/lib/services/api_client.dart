import 'package:dio/dio.dart';

import '../config/app_environment.dart';

class ApiRequestResult {
  const ApiRequestResult({
    required this.baseUrl,
    required this.path,
    required this.response,
  });

  final String baseUrl;
  final String path;
  final Response<dynamic> response;
}

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppEnvironment.connectTimeout,
              receiveTimeout: AppEnvironment.receiveTimeout,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              validateStatus: (status) => status != null && status < 600,
            ),
          );

  final Dio _dio;

  Future<Response<dynamic>> postToCandidates({
    required List<String> paths,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final result = await postResultToCandidates(
      paths: paths,
      body: body,
      token: token,
    );
    return result.response;
  }

  Future<ApiRequestResult> postResultToCandidates({
    required List<String> paths,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _requestCandidates(
      executor: (url, options) => _dio.post(url, data: body, options: options),
      paths: paths,
      token: token,
    );
  }

  Future<Response<dynamic>> getToCandidates({
    required List<String> paths,
    String? token,
  }) async {
    final result = await getResultToCandidates(paths: paths, token: token);
    return result.response;
  }

  Future<ApiRequestResult> getResultToCandidates({
    required List<String> paths,
    String? token,
  }) async {
    return _requestCandidates(
      executor: (url, options) => _dio.get(url, options: options),
      paths: paths,
      token: token,
    );
  }

  Future<ApiRequestResult> _requestCandidates({
    required Future<Response<dynamic>> Function(String url, Options options)
    executor,
    required List<String> paths,
    String? token,
  }) async {
    final attempts = <String>[];
    final requestOptions = _buildOptions(token);

    for (final baseUrl in AppEnvironment.baseUrls) {
      for (final path in paths) {
        final url = '$baseUrl$path';

        try {
          final response = await executor(url, requestOptions);
          final statusCode = response.statusCode ?? 0;

          if (statusCode >= 200 && statusCode < 300) {
            return ApiRequestResult(
              baseUrl: baseUrl,
              path: path,
              response: response,
            );
          }

          final message = _extractErrorMessage(response.data);
          attempts.add(
            '$url -> HTTP $statusCode${message.isEmpty ? '' : ' - $message'}',
          );

          if (statusCode == 401 || statusCode == 422) {
            throw Exception(
              message.isEmpty ? 'La API rechazó la solicitud.' : message,
            );
          }
        } on DioException catch (error) {
          attempts.add('$url -> ${error.message ?? 'Error de red'}');
        }
      }
    }

    throw Exception(
      'No fue posible completar la solicitud. Intentos: ${attempts.join(' | ')}',
    );
  }

  Options _buildOptions(String? token) {
    if (token == null || token.trim().isEmpty) {
      return Options();
    }

    return Options(headers: {'Authorization': 'Bearer ${token.trim()}'});
  }

  String _extractErrorMessage(Object? data) {
    if (data is String) {
      final compact = data.replaceAll(RegExp(r'\s+'), ' ').trim();
      return compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final direct = map['message'] ?? map['error'];
      if (direct != null && '$direct'.trim().isNotEmpty) {
        return '$direct'.trim();
      }

      final errors = map['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values.first.toString();
      }
    }

    return '';
  }
}
