class AppEnvironment {
  AppEnvironment._();

  /// Orden de prioridad exigido para resolver el backend.
  static const List<String> baseUrls = [
    'https://airbnbmob2.site',
    'http://67.205.172.167',
    'http://10.0.2.2:8000',
    'http://127.0.0.1:8000',
  ];

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);

  static const List<String> quickCities = [
    'Santa Cruz',
    'Cochabamba',
    'La Paz',
  ];

  /// Convierte rutas relativas del backend en URLs absolutas.
  static String resolveAssetUrl(String rawPath, {String? preferredBaseUrl}) {
    final normalized = rawPath.trim();

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final base = preferredBaseUrl ?? baseUrls.first;
    final safePath = normalized.startsWith('/') ? normalized : '/$normalized';
    return '$base$safePath';
  }
}
