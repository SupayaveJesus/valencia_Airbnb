import { inject, Injectable } from '@angular/core';

import { ApiClientService } from '../../http/api-client.service';
import { PlaceReservation } from '../models/place-reservation.model';

@Injectable({ providedIn: 'root' })
export class PlaceReservationsApiService {
  private readonly apiClient = inject(ApiClientService);

  async listByPlace(placeId: number): Promise<PlaceReservation[]> {
    // El ID del lugar viaja por URL porque el backend modela las reservas por recurso padre.
    const result = await this.apiClient.getFromCandidates<unknown>({
      paths: [`/api/reservas/lugar/${placeId}`],
    });

    // Igual que en lugares, primero normalizamos la lista y luego tipamos cada reserva.
    return this.normalizeList(result.body).map((item) =>
      PlaceReservation.fromApi(item, result.baseUrl),
    );
  }

  private normalizeList(raw: unknown): Record<string, unknown>[] {
    // Respuesta ideal: array directo.
    if (Array.isArray(raw)) {
      return raw
        .map((item) => this.readMap(item))
        .filter((item) => Object.keys(item).length > 0);
    }

    const map = this.readMap(raw);
    // Respuesta envuelta: buscamos la colección en claves frecuentes.
    const candidates = ['data', 'reservas', 'results', 'items'];

    for (const key of candidates) {
      const candidate = map[key];

      if (Array.isArray(candidate)) {
        return candidate
          .map((item) => this.readMap(item))
          .filter((item) => Object.keys(item).length > 0);
      }
    }

    // Si el backend no entregó una lista reconocible, devolvemos vacío y dejamos que la UI
    // decida cómo comunicar "sin reservas" o "sin datos válidos".
    return [];
  }

  private readMap(value: unknown): Record<string, unknown> {
    // Defensa mínima contra payloads mal formados.
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }

    return {};
  }
}
