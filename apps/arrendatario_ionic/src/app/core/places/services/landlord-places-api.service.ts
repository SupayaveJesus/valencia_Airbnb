import { inject, Injectable } from '@angular/core';

import { ApiClientService } from '../../http/api-client.service';
import { LandlordSession } from '../../auth/models/landlord-session.model';
import { LandlordPlaceDraft } from '../models/landlord-place-draft.model';
import { LandlordPlace } from '../models/landlord-place.model';

/**
 * La feature de lugares habla con un backend poco uniforme. Este servicio existe
 * para absorber esas diferencias y entregar modelos consistentes al resto de la UI.
 */
@Injectable({ providedIn: 'root' })
export class LandlordPlacesApiService {
  private readonly apiClient = inject(ApiClientService);

  // La documentación oficial y Postman discrepan entre singular y plural.
  // Centralizamos las variantes para no desparramar esa inconsistencia en toda la UI.
  private readonly savePlacePaths = ['/api/lugar', '/api/lugares'];

  async listByLandlord(session: LandlordSession): Promise<LandlordPlace[]> {
    // La API necesita saber qué arrendatario consulta; sin ID no existe contexto.
    if (!session.id) {
      throw new Error('No hay un identificador de arrendatario disponible para listar lugares.');
    }

    const result = await this.apiClient.getFromCandidates<unknown>({
      paths: [`/api/lugares/arrendatario/${session.id}`],
      token: session.token,
    });

    // Transformación API -> dominio: cualquier forma de lista se normaliza y luego
    // cada item se convierte en LandlordPlace para que la UI consuma un contrato estable.
    return this.normalizeList(result.body).map((item) =>
      LandlordPlace.fromApi(item, result.baseUrl),
    );
  }

  async getPlaceById(
    session: LandlordSession,
    placeId: number,
  ): Promise<LandlordPlace> {
    if (placeId <= 0) {
      throw new Error('No se recibió un identificador válido para cargar el lugar.');
    }

    const result = await this.apiClient.getFromCandidates<unknown>({
      paths: [`/api/lugares/${placeId}`, `/api/lugar/${placeId}`],
      token: session.token,
    });

    return LandlordPlace.fromApi(result.body, result.baseUrl);
  }

  async createPlace(
    session: LandlordSession,
    draft: LandlordPlaceDraft,
  ): Promise<{ place: LandlordPlace; uploadedPhotos: number; warningMessage: string }> {
    if (!session.id) {
      throw new Error('No hay un identificador de arrendatario disponible para crear lugares.');
    }

    // Primer paso: crear el lugar con sus datos estructurados.
    const createResult = await this.apiClient.postToCandidates<unknown>({
      paths: this.savePlacePaths,
      token: session.token,
      body: this.buildPlacePayload(session, draft),
    });

    // El backend puede devolver el lugar creado en distintas formas; este helper absorbe eso.
    const place = this.extractCreatedPlace(createResult.body, createResult.baseUrl);

    // Sin ID válido no se puede encadenar la segunda etapa de fotos.
    if (place.id <= 0) {
      throw new Error(
        'La API creó el lugar, pero no devolvió un ID válido para subir fotos.',
      );
    }

    let uploadedPhotos = 0;
    let warningMessage = '';

    try {
      // La API actual crea primero el lugar y después acepta las fotos una por una.
      uploadedPhotos = await this.uploadPlacePhotos(session, place.id, draft.photos);
    } catch (error) {
      warningMessage =
        error instanceof Error
          ? `El lugar se creó, pero falló la subida de fotos: ${error.message}`
          : 'El lugar se creó, pero falló la subida de fotos.';
    }

    return {
      place,
      uploadedPhotos,
      warningMessage,
    };
  }

  async updatePlace(
    session: LandlordSession,
    placeId: number,
    draft: LandlordPlaceDraft,
  ): Promise<{ place: LandlordPlace; uploadedPhotos: number; warningMessage: string }> {
    if (!session.id) {
      throw new Error('No hay un identificador de arrendatario disponible para editar lugares.');
    }

    if (placeId <= 0) {
      throw new Error('No se recibió un identificador válido para editar el lugar.');
    }

    // El mejor contrato disponible indica un guardado por POST enviando el id en el body.
    const updateResult = await this.apiClient.postToCandidates<unknown>({
      paths: this.savePlacePaths,
      token: session.token,
      body: this.buildPlacePayload(session, draft, placeId),
    });

    const place = this.extractCreatedPlace(updateResult.body, updateResult.baseUrl);

    let uploadedPhotos = 0;
    let warningMessage = '';

    try {
      uploadedPhotos = await this.uploadPlacePhotos(session, placeId, draft.photos);
    } catch (error) {
      warningMessage =
        error instanceof Error
          ? `El lugar se actualizó, pero falló la subida de fotos nuevas: ${error.message}`
          : 'El lugar se actualizó, pero falló la subida de fotos nuevas.';
    }

    return {
      place,
      uploadedPhotos,
      warningMessage,
    };
  }

  private async uploadPlacePhotos(
    session: LandlordSession,
    placeId: number,
    files: File[],
  ): Promise<number> {
    let uploadedPhotos = 0;

    // Se sube archivo por archivo porque el endpoint actual está diseñado así.
    for (const file of files) {
      const body = new FormData();

      // El backend espera exactamente este campo: foto
      body.append('foto', file, file.name);

      await this.apiClient.postFormDataToCandidates<unknown>({
        paths: [`/api/lugar/${placeId}/foto`, `/api/lugares/${placeId}/foto`],
        body,
        token: session.token,
      });

      uploadedPhotos += 1;
    }

    return uploadedPhotos;
  }

  private buildPlacePayload(
    session: LandlordSession,
    draft: LandlordPlaceDraft,
    placeId?: number,
  ): Record<string, unknown> {
    return {
      // Acá traducimos el draft del formulario al vocabulario exacto del backend.
      ...(placeId ? { id: placeId } : {}),
      nombre: draft.name,
      descripcion: draft.description,
      cantPersonas: draft.guests,
      cantCamas: draft.beds,
      cantBanios: draft.bathrooms,
      cantHabitaciones: draft.rooms,
      tieneWifi: draft.hasWifi ? 1 : 0,
      cantVehiculosParqueo: draft.parkingSlots,
      precioNoche: draft.pricePerNight.toFixed(2),
      costoLimpieza: draft.cleaningCost.toFixed(2),
      ciudad: draft.city,
      latitud: `${draft.latitude}`,
      longitud: `${draft.longitude}`,
      arrendatario_id: session.id,
    };
  }

  private extractCreatedPlace(raw: unknown, preferredBaseUrl?: string): LandlordPlace {
    // direct representa la respuesta al nivel actual, aunque quizá el lugar venga anidado.
    const direct = this.readMap(raw);

    // Probamos varias claves porque la API no es totalmente uniforme al devolver recursos creados.
    const nestedCandidates = ['data', 'lugar', 'place', 'item'];

    for (const key of nestedCandidates) {
      const nested = this.readMap(direct[key]);

      // Solo usamos mapas con contenido real; así evitamos convertir objetos vacíos en falsos positivos.
      if (Object.keys(nested).length > 0) {
        return LandlordPlace.fromApi(nested, preferredBaseUrl);
      }
    }

    // Si no hubo wrapper reconocible, intentamos mapear la respuesta tal como vino.
    return LandlordPlace.fromApi(direct, preferredBaseUrl);
  }

  private normalizeList(raw: unknown): Record<string, unknown>[] {
    // Caso simple: la API respondió un array directo de lugares.
    if (Array.isArray(raw)) {
      return raw
        .map((item) => this.readMap(item))
        .filter((item) => Object.keys(item).length > 0);
    }

    const map = this.readMap(raw);
    // Caso anidado: buscamos la lista dentro de wrappers comunes.
    const candidates = ['data', 'lugares', 'results', 'items'];

    for (const key of candidates) {
      const candidate = map[key];

      if (Array.isArray(candidate)) {
        return candidate
          .map((item) => this.readMap(item))
          .filter((item) => Object.keys(item).length > 0);
      }
    }

    // Algunas APIs devuelven un único objeto en vez de lista; lo envolvemos para que el resto
    // del flujo siempre reciba arrays.
    if (Object.keys(map).length > 0) {
      return [map];
    }

    // Sin datos válidos, preferimos array vacío antes que romper la UI aguas abajo.
    return [];
  }

  private readMap(value: unknown): Record<string, unknown> {
    // Este guard rail evita tratar arrays, null o primitivos como si fueran objetos JSON útiles.
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }

    return {};
  }
}
