import { computed, inject, Injectable, signal } from '@angular/core';

import { AppEnvironment } from '../../config/app-environment';
import { PreferencesStorageService } from '../../storage/preferences-storage.service';
import { LandlordSession } from '../models/landlord-session.model';

/**
 * Mantiene la sesión en memoria y la restaura una sola vez desde storage.
 * Así evitamos que cada página tenga que saber cómo persistimos o rehidratamos identidad.
 */
@Injectable({ providedIn: 'root' })
export class AuthSessionService {
  private readonly storage = inject(PreferencesStorageService);
  // sessionState es la fuente de verdad en memoria para toda la app actual.
  private readonly sessionState = signal<LandlordSession | null>(null);
  // initializedState distingue "todavía no restauré" de "restauré y no había sesión".
  private readonly initializedState = signal(false);
  // restorePromise evita dos restauraciones simultáneas si varias pantallas preguntan a la vez.
  private restorePromise?: Promise<void>;

  // Exponemos computed para lectura reactiva, no el signal mutable interno.
  readonly session = computed(() => this.sessionState());
  readonly initialized = computed(() => this.initializedState());
  readonly isAuthenticated = computed(() => this.sessionState()?.hasIdentity ?? false);

  async ensureRestored(): Promise<void> {
    // Si ya restauramos una vez, no hacemos trabajo extra.
    if (this.initializedState()) {
      return;
    }

    // La primera llamada crea la promesa; las siguientes esperan esa misma operación.
    if (!this.restorePromise) {
      this.restorePromise = this.restoreSession();
    }

    await this.restorePromise;
  }

  async openSession(session: LandlordSession): Promise<void> {
    // Primero actualizamos memoria para que la UI reaccione de inmediato.
    this.sessionState.set(session);
    this.initializedState.set(true);
    // Después persistimos una versión serializable para futuras aperturas de la app.
    await this.storage.set(
      AppEnvironment.sessionStorageKey,
      JSON.stringify(session.toJson()),
    );
  }

  async clearSession(): Promise<void> {
    // Limpiar memoria corta acceso instantáneamente en la interfaz actual.
    this.sessionState.set(null);
    this.initializedState.set(true);
    // También borramos storage para que el próximo arranque no reabra la identidad anterior.
    await this.storage.remove(AppEnvironment.sessionStorageKey);
  }

  private async restoreSession(): Promise<void> {
    try {
      const stored = await this.storage.get(AppEnvironment.sessionStorageKey);
      // fromStorage valida y normaliza el JSON persistido antes de confiar en él.
      const session = stored ? LandlordSession.fromStorage(stored) : null;
      // Solo conservamos sesiones con identidad usable; datos rotos se descartan.
      this.sessionState.set(session?.hasIdentity ? session : null);
    } finally {
      // finally garantiza que la app no quede "cargando sesión" para siempre si hubo error.
      this.initializedState.set(true);
      this.restorePromise = undefined;
    }
  }
}
