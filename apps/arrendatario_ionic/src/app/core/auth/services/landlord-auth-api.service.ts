import { inject, Injectable } from '@angular/core';

import { ApiClientService } from '../../http/api-client.service';
import { LandlordSession } from '../models/landlord-session.model';

export class LandlordAuthIdentityError extends Error {
  constructor(readonly detail: string) {
    super('El backend respondió, pero no devolvió una identidad usable para abrir la sesión.');
    this.name = 'LandlordAuthIdentityError';
  }
}

/**
 * Servicio de autenticación del arrendatario contra las rutas documentadas.
 * La UI le entrega credenciales; este servicio se ocupa de hablar con la API
 * y convertir la respuesta cruda en un modelo de sesión consistente.
 */
@Injectable({ providedIn: 'root' })
export class LandlordAuthApiService {
  private readonly apiClient = inject(ApiClientService);

  async login(email: string, password: string): Promise<LandlordSession> {
    const result = await this.apiClient.postToCandidates<unknown>({
      paths: ['/api/arrendatario/login'],
      body: {
        // Trim evita errores tontos de espacios copiados al pegar el correo.
        email: email.trim(),
        password,
      },
    });

    // Transformación clave: respuesta HTTP desconocida -> modelo de dominio usable.
    const session = LandlordSession.fromApi(result.body);

    // Si falta identidad mínima, preferimos fallar acá y no abrir una sesión fantasma.
    if (!session.hasIdentity) {
      throw new LandlordAuthIdentityError(
        `Respuesta recibida desde ${result.baseUrl}${result.path} sin id, email ni token reconocibles.`,
      );
    }

    return session;
  }

  async register(payload: {
    fullName: string;
    email: string;
    password: string;
    phone: string;
  }): Promise<{ session: LandlordSession | null; message: string }> {
    const result = await this.apiClient.postToCandidates<unknown>({
      paths: ['/api/arrendatario/registro'],
      body: {
        // Acá traducimos nombres del formulario a los nombres que espera la API actual.
        nombrecompleto: payload.fullName.trim(),
        email: payload.email.trim(),
        password: payload.password,
        telefono: payload.phone.trim(),
      },
    });

    // Algunas APIs registran y devuelven sesión; otras solo confirman el alta.
    const session = LandlordSession.fromApi(result.body);
    const message = this.extractRegisterMessage(result.body);

    return {
      session: session.hasIdentity ? session : null,
      message,
    };
  }

  private extractRegisterMessage(raw: unknown): string {
    const data = raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : {};
    // Leemos message/mensaje porque el backend no siempre es consistente en el idioma.
    const direct = `${data['message'] ?? data['mensaje'] ?? ''}`.trim();

    // Fallback amable para no dejar a la UI sin texto navegable.
    return direct || 'Registro completado. Ahora ya podés continuar en la app.';
  }
}
