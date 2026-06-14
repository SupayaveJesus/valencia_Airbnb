import { CommonModule } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import {
  IonButton,
  IonCard,
  IonCardContent,
  IonContent,
  IonImg,
  IonSpinner,
  IonText,
} from '@ionic/angular/standalone';

import { PlaceReservation } from '../../core/places/models/place-reservation.model';
import { PlaceReservationsApiService } from '../../core/places/services/place-reservations-api.service';

@Component({
  selector: 'app-place-reservations-page',
  standalone: true,
  templateUrl: './place-reservations.page.html',
  styleUrl: './place-reservations.page.scss',
  imports: [
    CommonModule,
    IonButton,
    IonCard,
    IonCardContent,
    IonContent,
    IonImg,
    IonSpinner,
    IonText,
  ],
})
export class PlaceReservationsPage implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly reservationsApi = inject(PlaceReservationsApiService);

  // Estado básico de carga/lista/error, igual que en otras páginas de datos.
  readonly loading = signal(false);
  readonly errorMessage = signal('');
  readonly reservations = signal<PlaceReservation[]>([]);

  // placeId viene de la URL; placeName se intenta enriquecer con navigation state.
  placeId = 0;
  placeName = 'Lugar seleccionado';
  returnUrl = '/app/lugares';

  ngOnInit(): void {
    // Leemos el parámetro apenas inicia la página porque define toda la consulta posterior.
    this.placeId = Number.parseInt(this.route.snapshot.paramMap.get('id') ?? '0', 10) || 0;

    // history.state conserva datos de navegación no críticos, como el nombre visible del lugar.
    const state = history.state as { placeName?: string };

    if (state.placeName) {
      this.placeName = state.placeName;
    }

    if (typeof (history.state as { returnUrl?: string }).returnUrl === 'string') {
      this.returnUrl = (history.state as { returnUrl: string }).returnUrl;
    }

    void this.loadReservations();
  }

  async loadReservations(): Promise<void> {
    // Sin ID no se puede consultar nada; frenamos antes de golpear la API.
    if (!this.placeId) {
      this.errorMessage.set('No se recibió el ID del lugar.');
      return;
    }

    this.loading.set(true);
    this.errorMessage.set('');

    try {
      // listByPlace ya entrega modelos PlaceReservation listos para la plantilla.
      const result = await this.reservationsApi.listByPlace(this.placeId);
      this.reservations.set(result);
    } catch (error) {
      this.errorMessage.set(
        error instanceof Error
          ? error.message
          : 'No se pudieron cargar las reservas del lugar.',
      );
    } finally {
      this.loading.set(false);
    }
  }

  goBack(): Promise<boolean> {
    // Si llegamos desde edición, volvemos ahí; si no, caemos al listado general.
    return this.router.navigateByUrl(this.returnUrl);
  }
}
