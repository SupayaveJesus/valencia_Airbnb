class AppEnvironment {
  AppEnvironment._();

/// Lista de hosts base para el backend. El orden refleja la prioridad de uso:
  /// - El primero es el que se recomienda usar en producción.
  /// - Los siguientes son alternativas para desarrollo local o despliegues temporales.
  static const List<String> baseUrls = [
    'http://67.205.172.167',
    'https://airbnbmob2.site',
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
  ///
  /// El backend a veces entrega `/storage/...` en lugar de una URL completa.
  /// Este helper transforma esa referencia en una URL usable para que la UI
  /// solo piense en mostrar la imagen, no en reconstruir hosts manualmente.
  static String resolveAssetUrl(String rawPath, {String? preferredBaseUrl}) {
    final normalized = rawPath.trim();

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    // Si un service sabe qué host respondió, lo reutiliza para mantener la
    // misma procedencia de datos y assets. Si no, usamos la base prioritaria.
    final base = preferredBaseUrl ?? baseUrls.first;
    final safePath = normalized.startsWith('/') ? normalized : '/$normalized';
    return '$base$safePath';
  }
}
