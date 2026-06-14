import { AppEnvironment } from '../../config/app-environment';

export class LandlordPlace {
  constructor(
    // Guardamos solo campos que la UI realmente usa seguido.
    // rawData queda disponible para debugging o futuras extensiones sin perder la respuesta original.
    readonly id: number,
    readonly name: string,
    readonly city: string,
    readonly description: string,
    readonly pricePerNight: number,
    readonly guests: number,
    readonly imageUrl: string,
    readonly rawData: Record<string, unknown>,
    readonly beds = 0,
    readonly bathrooms = 0,
    readonly rooms = 0,
    readonly hasWifi = false,
    readonly parkingSlots = 0,
    readonly cleaningCost = 0,
    readonly latitude = 0,
    readonly longitude = 0,
    readonly photos: string[] = [],
  ) {}

  get priceLabel(): string {
    // Getter de presentación: evita repetir formato monetario en cada template.
    return this.pricePerNight > 0
      ? `Bs. ${this.pricePerNight.toFixed(2)} por noche`
      : 'Precio no informado';
  }

  get guestsLabel(): string {
    // También resuelve el caso vacío para que la UI no tenga que preguntar dos veces.
    return this.guests > 0 ? `${this.guests} huéspedes` : 'Capacidad no informada';
  }

  get hasParking(): boolean {
    // En este proyecto el parqueo se expresa por cantidad de vehículos disponibles.
    return this.parkingSlots > 0;
  }

  static fromApi(raw: unknown, preferredBaseUrl?: string): LandlordPlace {
    // Entrada: payload arbitrario de backend.
    // Salida: instancia tipada con defaults seguros para renderizar sin romper la vista.
    const json = LandlordPlace.readMap(raw);
    const photos = LandlordPlace.resolvePhotos(json, preferredBaseUrl);

    return new LandlordPlace(
      LandlordPlace.readInt(json['id']),
      LandlordPlace.readString(json['nombre'] ?? json['name']) || 'Lugar sin nombre',
      LandlordPlace.readString(json['ciudad'] ?? json['city']) || 'Ciudad no informada',
      LandlordPlace.readString(json['descripcion'] ?? json['description']) ||
        'Sin descripción disponible.',
      LandlordPlace.readNumber(json['precioNoche']),
      LandlordPlace.readInt(json['cantPersonas'] ?? json['capacidad']),
      photos[0] ?? '',
      json,
      LandlordPlace.readInt(json['cantCamas']),
      LandlordPlace.readInt(json['cantBanios']),
      LandlordPlace.readInt(json['cantHabitaciones']),
      LandlordPlace.readBoolean(json['tieneWifi']),
      LandlordPlace.readInt(json['cantVehiculosParqueo']),
      LandlordPlace.readNumber(json['costoLimpieza']),
      LandlordPlace.readNumber(json['latitud'] ?? json['latitude']),
      LandlordPlace.readNumber(json['longitud'] ?? json['longitude']),
      photos,
    );
  }

  private static resolvePhotos(
    json: Record<string, unknown>,
    preferredBaseUrl?: string,
  ): string[] {
    const resolvedPhotos: string[] = [];

    // Primer intento: la API ya trae una foto principal en una sola propiedad.
    const direct = LandlordPlace.readString(json['foto'] ?? json['imagen'] ?? json['image']);
    if (direct) {
      resolvedPhotos.push(AppEnvironment.resolveAssetUrl(direct, preferredBaseUrl));
    }

    const photos = json['fotos'];
    if (Array.isArray(photos)) {
      // Segundo intento: recorremos la colección y guardamos cada foto usable.
      for (const item of photos) {
        if (typeof item === 'string' && item.trim()) {
          resolvedPhotos.push(
            AppEnvironment.resolveAssetUrl(item.trim(), preferredBaseUrl),
          );
          continue;
        }

        const mapped = LandlordPlace.readMap(item);
        // Algunos backends anidan la URL bajo distintas claves; probamos varias.
        const candidate = LandlordPlace.readString(
          mapped['url'] ?? mapped['foto'] ?? mapped['path'],
        );
        if (candidate) {
          resolvedPhotos.push(
            AppEnvironment.resolveAssetUrl(candidate, preferredBaseUrl),
          );
        }
      }
    }

    // Evitamos fotos repetidas cuando la API trae una foto principal y la repite en la colección.
    return Array.from(new Set(resolvedPhotos.filter(Boolean)));
  }

  private static readMap(value: unknown): Record<string, unknown> {
    // Solo aceptamos objetos planos como base del mapeo.
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }

    return {};
  }

  private static readString(value: unknown): string {
    // Normalización tolerante para strings, números u otros valores serializables.
    return value == null ? '' : `${value}`.trim();
  }

  private static readInt(value: unknown): number {
    if (typeof value === 'number') {
      // Truncamos porque IDs/cantidades enteras no deberían conservar decimales extraños.
      return Number.isFinite(value) ? Math.trunc(value) : 0;
    }

    return Number.parseInt(`${value ?? ''}`, 10) || 0;
  }

  private static readNumber(value: unknown): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : 0;
    }

    // Si parseFloat falla, devolvemos 0 para mantener el modelo seguro de renderizar.
    return Number.parseFloat(`${value ?? ''}`) || 0;
  }

  private static readBoolean(value: unknown): boolean {
    // La API mezcla enteros, strings y booleanos; este helper unifica el criterio.
    if (typeof value === 'boolean') {
      return value;
    }

    const normalized = `${value ?? ''}`.trim().toLowerCase();
    return normalized === '1' || normalized === 'true' || normalized === 'si';
  }
}
