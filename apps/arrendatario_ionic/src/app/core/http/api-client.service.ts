import { HttpClient, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { firstValueFrom } from 'rxjs';

import { AppEnvironment } from '../config/app-environment';

export interface ApiRequestResult<T> {
  // baseUrl y path se devuelven por separado para que otras capas puedan reutilizar
  // el host exitoso, por ejemplo al reconstruir URLs de imágenes.
  baseUrl: string;
  path: string;
  body: T;
}

export interface ApiAttemptDetail {
  // Guardamos diagnóstico por intento para mostrarle al usuario o al desarrollador
  // exactamente qué URL falló y cómo falló.
  url: string;
  status: number;
  message: string;
}

export type ApiRequestFailureKind = 'network' | 'auth' | 'server';

/**
 * Error tipado para que la UI pueda reaccionar distinto ante red caída,
 * credenciales rechazadas o errores generales del backend.
 */
export class ApiRequestError extends Error {
  constructor(
    message: string,
    readonly kind: ApiRequestFailureKind,
    readonly attempts: ApiAttemptDetail[],
    readonly status?: number,
  ) {
    super(message);
    this.name = 'ApiRequestError';
  }
}

/**
 * Este servicio centraliza el contrato HTTP para no repetir headers, token,
 * fallback de base URL y traducción de errores en cada feature.
 */
@Injectable({ providedIn: 'root' })
export class ApiClientService {
  private readonly http = inject(HttpClient);

  async getFromCandidates<T>({
    paths,
    token,
  }: {
    paths: string[];
    token?: string;
  }): Promise<ApiRequestResult<T>> {
    // GET se expresa como un caso particular del request genérico.
    // Así centralizamos retry entre hosts, headers y manejo de errores.
    return this.requestCandidates<T>({
      paths,
      token,
      contentType: 'json',
      executor: (url, headers) => firstValueFrom(this.http.get<T>(url, { headers })),
    });
  }

  async postToCandidates<T>({
    paths,
    body,
    token,
  }: {
    paths: string[];
    body: Record<string, unknown>;
    token?: string;
  }): Promise<ApiRequestResult<T>> {
    // Para JSON, el body ya viene normalizado desde la capa de caso de uso.
    return this.requestCandidates<T>({
      paths,
      token,
      contentType: 'json',
      executor: (url, headers) =>
        firstValueFrom(this.http.post<T>(url, body, { headers })),
    });
  }

  async postFormDataToCandidates<T>({
    paths,
    body,
    token,
  }: {
    paths: string[];
    body: FormData;
    token?: string;
  }): Promise<ApiRequestResult<T>> {
    // multipart NO debe fijar Content-Type manualmente: el navegador agrega el boundary.
    return this.requestCandidates<T>({
      paths,
      token,
      contentType: 'multipart',
      executor: (url, headers) =>
        firstValueFrom(this.http.post<T>(url, body, { headers })),
    });
  }

  private async requestCandidates<T>({
    paths,
    token,
    contentType,
    executor,
  }: {
    paths: string[];
    token?: string;
    contentType: 'json' | 'multipart';
    executor: (url: string, headers: HttpHeaders) => Promise<T>;
  }): Promise<ApiRequestResult<T>> {
    const attempts: ApiAttemptDetail[] = [];
    // Se construyen una sola vez porque todos los intentos comparten token/Content-Type.
    const headers = this.buildHeaders(token, contentType);

    // Probamos combinación de host + path. Esto desacopla a las features de detalles
    // de conectividad o rutas alternativas del backend.
    for (const baseUrl of AppEnvironment.baseUrls) {
      for (const path of paths) {
        const url = `${baseUrl}${path}`;

        try {
          const body = await executor(url, headers);
          // Si una combinación funciona, devolvemos de inmediato y no seguimos intentando.
          return { baseUrl, path, body };
        } catch (error) {
          const attempt = this.describeAttempt(url, error);
          attempts.push(attempt);

          // 401/422 se consideran errores funcionales de autenticación/validación.
          // Ahí NO tiene sentido seguir probando otros hosts porque el problema no es de red.
          if (error instanceof HttpErrorResponse && [401, 422].includes(error.status)) {
            throw new ApiRequestError(
              this.extractErrorMessage(error) || 'Las credenciales no fueron aceptadas.',
              'auth',
              attempts,
              error.status,
            );
          }
        }
      }
    }

    throw this.buildAggregateError(attempts);
  }

  private buildHeaders(token?: string, contentType: 'json' | 'multipart' = 'json'): HttpHeaders {
    // Accept comunica el formato que esperamos recibir del backend.
    let headers = new HttpHeaders({
      Accept: 'application/json',
    });

    // Solo fijamos Content-Type en JSON. En FormData lo dejamos libre a propósito.
    if (contentType === 'json') {
      headers = headers.set('Content-Type', 'application/json');
    }

    // Token vacío o con espacios NO se manda para evitar headers engañosos.
    if (token?.trim()) {
      headers = headers.set('Authorization', `Bearer ${token.trim()}`);
    }

    return headers;
  }

  private buildAggregateError(attempts: ApiAttemptDetail[]): ApiRequestError {
    // Si todos los estados son 0, Angular ni siquiera recibió respuesta HTTP real.
    const allNetworkFailures = attempts.length > 0 && attempts.every((attempt) => attempt.status === 0);

    if (allNetworkFailures) {
      return new ApiRequestError(
        'No hubo respuesta del servidor. Revisá conexión, CORS o certificados del backend.',
        'network',
        attempts,
        0,
      );
    }

    return new ApiRequestError(
      'El servidor no pudo completar el ingreso con las rutas disponibles.',
      'server',
      attempts,
    );
  }

  private describeAttempt(url: string, error: unknown): ApiAttemptDetail {
    if (error instanceof HttpErrorResponse) {
      return {
        url,
        // Angular usa status 0 cuando la llamada no llega a completarse.
        status: error.status || 0,
        message: this.extractErrorMessage(error) || (error.status === 0 ? 'Sin respuesta útil.' : 'Sin detalle adicional.'),
      };
    }

    // Fallback defensivo para errores que no vienen tipados como HttpErrorResponse.
    return {
      url,
      status: 0,
      message: 'Error de red.',
    };
  }

  private extractErrorMessage(error: HttpErrorResponse): string {
    const payload = error.error;

    // A veces el backend responde texto plano en vez de JSON.
    if (typeof payload === 'string') {
      return payload.trim();
    }

    if (payload && typeof payload === 'object') {
      const map = payload as Record<string, unknown>;
      // Probamos claves frecuentes en español e inglés para tolerar APIs inconsistentes.
      const direct = this.readString(map['message'] ?? map['mensaje'] ?? map['error']);
      if (direct) {
        return direct;
      }

      const errors = map['errors'];
      if (errors && typeof errors === 'object') {
        // Algunos backends agrupan errores por campo; tomamos el primero visible.
        const first = Object.values(errors as Record<string, unknown>)[0];
        return this.readString(first);
      }

      if (Array.isArray(errors)) {
        // Otros devuelven una lista simple. De nuevo, leemos el primer mensaje disponible.
        return this.readString(errors[0]);
      }
    }

    // Vacío significa "no supimos extraer texto útil"; la capa superior elegirá el mensaje final.
    return '';
  }

  private readString(value: unknown): string {
    // Conversión defensiva: cualquier valor printable pasa a string y se limpia.
    return value == null ? '' : `${value}`.trim();
  }
}
