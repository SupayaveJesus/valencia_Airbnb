import { Injectable } from '@angular/core';
// Preferences da una API estable para persistencia simple tanto en web como en mobile.
import { Preferences } from '@capacitor/preferences';

@Injectable({ providedIn: 'root' })
export class PreferencesStorageService {
  // Esta capa parece pequeña, pero es clave: evita que páginas y servicios dependan
  // directamente de Capacitor. Si mañana cambia el mecanismo de storage, el impacto
  // queda encapsulado acá.
  get(key: string): Promise<string | null> {
    // Preferences devuelve un objeto { value }; esta función entrega solo el dato útil.
    return Preferences.get({ key }).then((result) => result.value);
  }

  set(key: string, value: string): Promise<void> {
    // Guardamos siempre strings porque la serialización la decide la capa de dominio.
    return Preferences.set({ key, value });
  }

  remove(key: string): Promise<void> {
    // Borrar la clave es más claro que guardar "null" y obliga a restaurar desde cero.
    return Preferences.remove({ key });
  }
}
