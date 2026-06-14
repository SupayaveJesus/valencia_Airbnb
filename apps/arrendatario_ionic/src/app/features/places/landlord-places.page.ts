import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import {
  IonButton,
  IonCard,
  IonCardContent,
  IonContent,
  IonList,
  IonNote,
  IonSpinner,
  IonText,
} from '@ionic/angular/standalone';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { LandlordPlace } from '../../core/places/models/landlord-place.model';
import { LandlordPlacesApiService } from '../../core/places/services/landlord-places-api.service';

/**
 * Esta página resume el inventario del arrendatario con foco en lectura rápida.
 * La transformación visual queda acá para no contaminar el servicio con decisiones de presentación.
 */
@Component({
  selector: 'app-landlord-places-page',
  standalone: true,
  templateUrl: './landlord-places.page.html',
  styleUrl: './landlord-places.page.scss',
  imports: [
    CommonModule,
    IonButton,
    IonCard,
    IonCardContent,
    IonContent,
    IonList,
    IonNote,
    IonSpinner,
    IonText,
  ],
})
export class LandlordPlacesPage {
  private readonly authSession = inject(AuthSessionService);
  private readonly placesApi = inject(LandlordPlacesApiService);
  private readonly router = inject(Router);

  // loading, error y places modelan los tres estados básicos del listado.
  readonly loading = signal(true);
  readonly errorMessage = signal('');
  // El listado puede mostrar mensajes de retorno desde otras pantallas, por ejemplo creación exitosa.
  readonly noticeMessage = signal(this.readNavigationMessage());
  readonly places = signal<LandlordPlace[]>([]);

  constructor() {
    // Cargamos apenas se crea la página para que el template pueda reaccionar a loading.
    void this.loadPlaces();
  }

  async reload(): Promise<void> {
    // Método separado para reutilizar la misma lógica desde un botón "reintentar".
    await this.loadPlaces();
  }

  async goToCreatePlace(): Promise<void> {
    await this.router.navigateByUrl('/app/lugares/nuevo');
  }

  async goToEditPlace(place: LandlordPlace): Promise<void> {
    // La edición es ahora el punto de entrada natural para revisar y luego ver reservas.
    await this.router.navigateByUrl(`/app/lugares/${place.id}/editar`);
  }

  async goToReservations(place: LandlordPlace): Promise<void> {
    // Dejamos un acceso directo porque en móvil reduce pasos y evita depender de una card ancha.
    await this.router.navigate([`/app/lugares/${place.id}/reservas`], {
      state: {
        placeName: place.name,
        returnUrl: '/app/lugares',
      },
    });
  }

  hasPhoto(place: LandlordPlace): boolean {
    // La vista necesita saber si renderiza <img> o el avatar textual de fallback.
    return place.imageUrl.trim().length > 0;
  }

  photoFallbackInitials(place: LandlordPlace): string {
    // Convertimos el nombre del lugar en iniciales para un placeholder más informativo.
    const words = place.name
      .split(/\s+/)
      .map((word) => word.trim())
      .filter(Boolean);

    if (words.length === 0) {
      // "SP" = Sin Palabras / Sin nombre útil.
      return 'SP';
    }

    return words
      .slice(0, 2)
      .map((word) => word[0]?.toUpperCase() ?? '')
      .join('');
  }

  private async loadPlaces(): Promise<void> {
    // Reiniciamos estado visual en cada carga, no solo la primera vez.
    this.loading.set(true);
    this.errorMessage.set('');

    try {
      // El listado depende de la identidad actual; por eso restauramos sesión antes de consultar.
      await this.authSession.ensureRestored();
      const session = this.authSession.session();

      if (!session) {
        throw new Error('La sesión no está disponible para consultar tus lugares.');
      }

      // Resultado final: array de LandlordPlace listo para pintar.
      this.places.set(await this.placesApi.listByLandlord(session));
    } catch (error) {
      // Ante error limpiamos la lista para no dejar datos viejos mezclados con el fallo actual.
      this.places.set([]);
      this.errorMessage.set(
        error instanceof Error ? error.message : 'No se pudo cargar el listado de lugares.',
      );
    } finally {
      this.loading.set(false);
    }
  }

  private readNavigationMessage(): string {
    // Igual que en login, leemos el mensaje de navegación una sola vez al entrar.
    const message = this.router.getCurrentNavigation()?.extras.state?.['message'];
    return typeof message === 'string' ? message.trim() : '';
  }
}
