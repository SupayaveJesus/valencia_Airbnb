class AppEnvironment {
  AppEnvironment._();

  /// CONTINGENCIA TEMPORAL PARA LA DEFENSA / DEMO.
  ///
  /// Cambia este valor a `false` cuando quieras volver a usar solamente la API
  /// real del docente. La idea es que exista UN ÚNICO punto obvio de cambio,
  /// fácil de mostrar y fácil de revertir cuando el backend vuelva a estar
  /// estable.
  static const bool useMockServices = true;

  /// Indicador visual simple para evitar confundir una demo mock con datos
  /// verdaderos del backend.
  static const bool showMockIndicator = true;

  static String get dataSourceLabel =>
      useMockServices ? 'MOCK / CONTINGENCIA' : 'API REAL';

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
