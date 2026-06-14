import { Routes } from '@angular/router';

// Importamos ambos guards desde un solo archivo porque la decisión de acceso
// vive en la capa de auth, no dispersa en cada pantalla.
import { authGuard, publicOnlyGuard } from './core/auth/guards/auth.guard';

/**
 * Este archivo separa el flujo público del flujo interno para que la navegación
 * exprese la arquitectura: primero se resuelve la sesión y recién después se carga el shell.
 */
export const routes: Routes = [
  {
    // La raíz no muestra pantalla propia: redirige al punto de entrada público.
    path: '',
    redirectTo: 'login',
    pathMatch: 'full',
  },
  {
    // Login solo debe estar disponible si TODAVÍA no hay sesión activa.
    path: 'login',
    canActivate: [publicOnlyGuard],
    // Lazy loading: Angular descarga esta pantalla cuando realmente se necesita.
    loadComponent: () =>
      import('./features/auth/login.page').then((m) => m.LoginPage),
  },
  {
    // Registro comparte la misma regla que login: si ya ingresó, no vuelve acá.
    path: 'register',
    canActivate: [publicOnlyGuard],
    loadComponent: () =>
      import('./features/auth/register.page').then((m) => m.RegisterPage),
  },
  {
    // Todo lo que cuelga de /app pertenece al área autenticada de la aplicación.
    path: 'app',
    canActivate: [authGuard],
    // El shell interno aporta cabecera y outlet; no es una pantalla de negocio.
    loadComponent: () =>
      import('./features/shell/internal-shell.page').then(
        (m) => m.InternalShellPage,
      ),
    children: [
      {
        // Listado principal: funciona como home real del arrendatario autenticado.
        path: 'lugares',
        loadComponent: () =>
          import('./features/places/landlord-places.page').then(
            (m) => m.LandlordPlacesPage
          ),
      },
      {
        // Ruta dedicada al formulario de alta. No mezcla crear con listar.
        path: 'lugares/nuevo',
        loadComponent: () =>
          import('./features/places/landlord-place-form.page').then(
            (m) => m.LandlordPlaceFormPage
          ),
      },
      {
        // La edición reutiliza el mismo formulario, pero entra con un ID real.
        path: 'lugares/:id/editar',
        loadComponent: () =>
          import('./features/places/landlord-place-form.page').then(
            (m) => m.LandlordPlaceFormPage
          ),
      },
      {
        // :id identifica qué lugar se usa para consultar sus reservas.
        path: 'lugares/:id/reservas',
        loadComponent: () =>
          import('./features/places/place-reservations.page').then(
            (m) => m.PlaceReservationsPage
          ),
      },
      {
        // Si el usuario entra a /app sin subruta, se lo lleva al listado base.
        path: '',
        redirectTo: 'lugares',
        pathMatch: 'full',
      },
    ],
  },
];
