import { AppEnvironment } from '../../config/app-environment';

export class PlaceReservation {
  constructor(
    // Igual que en LandlordPlace, este modelo ofrece un contrato predecible a la UI.
    readonly id: number,
    readonly fechaInicio: string,
    readonly fechaFin: string,
    readonly precioTotal: number,
    readonly precioLimpieza: number,
    readonly precioNoches: number,
    readonly precioServicio: number,
    readonly clienteNombre: string,
    readonly imageUrl: string,
    readonly rawData: Record<string, unknown>,
  ) {}

  get totalLabel(): string {
    // Centralizamos el formato monetario para no repetirlo en templates o páginas.
    return `Bs. ${this.precioTotal.toFixed(2)}`;
  }

  get nochesLabel(): string {
    // Este getter reutiliza la lógica de cantidadNoches y le agrega texto listo para mostrar.
    const noches = this.cantidadNoches;

    if (noches <= 0) {
      return 'Noches no informadas';
    }

    return noches === 1 ? '1 noche' : `${noches} noches`;
  }

  get cantidadNoches(): number {
    // Convertimos texto ISO/fecha a Date para calcular diferencia de noches.
    const inicio = new Date(this.fechaInicio);
    const fin = new Date(this.fechaFin);

    // Si alguna fecha es inválida, devolvemos 0 antes de propagar NaN a la UI.
    if (Number.isNaN(inicio.getTime()) || Number.isNaN(fin.getTime())) {
      return 0;
    }

    const diferencia = fin.getTime() - inicio.getTime();
    const noches = diferencia / (1000 * 60 * 60 * 24);

    // Solo aceptamos estadías positivas. Reservas mal formadas no generan noches negativas.
    return noches > 0 ? Math.round(noches) : 0;
  }

  static fromApi(raw: unknown, preferredBaseUrl?: string): PlaceReservation {
    // Entrada: reserva cruda desde API.
    // Salida: reserva lista para renderizar con cliente, totales y foto normalizados.
    const json = PlaceReservation.readMap(raw);

    // Algunas propiedades útiles vienen anidadas; por eso las extraemos primero.
    const cliente = PlaceReservation.readMap(json['cliente']);
    const lugar = PlaceReservation.readMap(json['lugar']);

    // Probamos múltiples nombres porque el backend no expone un contrato completamente uniforme.
    const clienteNombre =
      PlaceReservation.readString(cliente['nombrecompleto']) ||
      PlaceReservation.readString(cliente['nombre']) ||
      PlaceReservation.readString(json['cliente_nombre']) ||
      'Cliente sin nombre';

    return new PlaceReservation(
      PlaceReservation.readInt(json['id']),
      PlaceReservation.readString(json['fechaInicio']),
      PlaceReservation.readString(json['fechaFin']),
      PlaceReservation.readNumber(json['precioTotal']),
      PlaceReservation.readNumber(json['precioLimpieza']),
      PlaceReservation.readNumber(json['precioNoches']),
      PlaceReservation.readNumber(json['precioServicio']),
      clienteNombre,
      PlaceReservation.resolvePhoto(lugar, preferredBaseUrl),
      json,
    );
  }

  private static resolvePhoto(
    json: Record<string, unknown>,
    preferredBaseUrl?: string,
  ): string {
    // Foto directa del lugar si existe.
    const direct = PlaceReservation.readString(
      json['foto'] ?? json['imagen'] ?? json['image'],
    );

    if (direct) {
      return AppEnvironment.resolveAssetUrl(direct, preferredBaseUrl);
    }

    const photos = json['fotos'];

    if (Array.isArray(photos)) {
      // Si hay galería, usamos la primera foto aprovechable como miniatura.
      for (const item of photos) {
        if (typeof item === 'string' && item.trim()) {
          return AppEnvironment.resolveAssetUrl(item.trim(), preferredBaseUrl);
        }

        const mapped = PlaceReservation.readMap(item);
        // Fallback ante distintas estructuras internas de la colección de fotos.
        const candidate = PlaceReservation.readString(
          mapped['url'] ?? mapped['foto'] ?? mapped['path'],
        );

        if (candidate) {
          return AppEnvironment.resolveAssetUrl(candidate, preferredBaseUrl);
        }
      }
    }

    // Sin foto no es error: la página puede mostrar reserva sin imagen.
    return '';
  }

  private static readMap(value: unknown): Record<string, unknown> {
    // Mismo criterio defensivo que en otros modelos: solo objetos planos sirven para mapear.
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }

    return {};
  }

  private static readString(value: unknown): string {
    return value == null ? '' : `${value}`.trim();
  }

  private static readInt(value: unknown): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? Math.trunc(value) : 0;
    }

    return Number.parseInt(`${value ?? ''}`, 10) || 0;
  }

  private static readNumber(value: unknown): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : 0;
    }

    // parseFloat absorbe números enviados como string; si falla, preferimos 0 estable.
    return Number.parseFloat(`${value ?? ''}`) || 0;
  }
}
