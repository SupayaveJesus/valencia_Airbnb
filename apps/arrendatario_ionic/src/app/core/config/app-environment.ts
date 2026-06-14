export class AppEnvironment {
  // Constructor privado: esta clase solo agrupa constantes y utilidades estáticas.
  private constructor() {}

  // Lista de hosts candidatos. El cliente HTTP puede probar varios si el proyecto
  // necesita tolerar diferencias entre despliegues o rutas disponibles.
  static readonly baseUrls = [
    'http://67.205.172.167',
  ] as const;

  // Clave única para guardar la sesión persistida del arrendatario.
  static readonly sessionStorageKey = 'arrendatario_session';

  static resolveAssetUrl(rawPath: string, preferredBaseUrl?: string): string {
    // Siempre limpiamos espacios porque la API puede devolver strings poco prolijos.
    const normalized = rawPath.trim();

    // Si no vino path útil, devolvemos vacío para que la UI aplique su placeholder.
    if (!normalized) {
      return '';
    }

    // Si ya es URL absoluta, NO la tocamos: modificarla podría romperla.
    if (
      normalized.startsWith('http://') ||
      normalized.startsWith('https://')
    ) {
      return normalized;
    }

    // Si la API devuelve algo como: 67.205.172.167/fotos/33.jpg
    if (normalized.startsWith('67.205.172.167')) {
      return `http://${normalized}`;
    }

    // preferredBaseUrl permite reutilizar el mismo host que respondió la API.
    // Si no se informa, usamos el primer host configurado como default.
    const baseUrl = preferredBaseUrl ?? AppEnvironment.baseUrls[0];

    // Aseguramos exactamente una barra entre host y recurso.
    return `${baseUrl}${normalized.startsWith('/') ? normalized : `/${normalized}`}`;
  }
}
