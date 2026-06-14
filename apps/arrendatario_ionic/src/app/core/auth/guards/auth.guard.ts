import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';

import { AuthSessionService } from '../services/auth-session.service';

/**
 * Los guards no validan credenciales por sí mismos: fuerzan a restaurar la sesión
 * persistida para que toda decisión de acceso salga de una única fuente de verdad.
 */
export const authGuard: CanActivateFn = async () => {
  const authSession = inject(AuthSessionService);
  const router = inject(Router);

  // Antes de decidir acceso, restauramos storage -> memoria.
  // Sin esto, un refresh podría parecer "logout" aunque la sesión siga guardada.
  await authSession.ensureRestored();

  // Si hay sesión, dejamos pasar. Si no, devolvemos una UrlTree para que Angular
  // redirija al login sin que la página protegida llegue a renderizarse.
  return authSession.isAuthenticated()
    ? true
    : router.createUrlTree(['/login']);
};

export const publicOnlyGuard: CanActivateFn = async () => {
  const authSession = inject(AuthSessionService);
  const router = inject(Router);

  // Repetimos la restauración porque las rutas públicas también necesitan saber
  // si el usuario YA estaba autenticado en una visita anterior.
  await authSession.ensureRestored();

  // Si ya inició sesión, entrar a login/register no aporta nada:
  // se lo deriva directo al área útil de trabajo.
  return authSession.isAuthenticated()
    ? router.createUrlTree(['/app/lugares'])
    : true;
};

export const entryGuard: CanActivateFn = async () => {
  const authSession = inject(AuthSessionService);
  const router = inject(Router);

  await authSession.ensureRestored();

  // Este guard no "permite o bloquea". Siempre redirige al destino correcto
  // según el estado actual de autenticación.
  return router.createUrlTree([
    authSession.isAuthenticated() ? '/app/lugares' : '/login',
  ]);
};
