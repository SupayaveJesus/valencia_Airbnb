import { CommonModule } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import {
  IonButton,
  IonCard,
  IonCardContent,
  IonContent,
  IonInput,
  IonItem,
  IonNote,
  IonSpinner,
  IonText,
  IonTextarea,
} from '@ionic/angular/standalone';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { LandlordPlaceDraft } from '../../core/places/models/landlord-place-draft.model';
import { LandlordPlace } from '../../core/places/models/landlord-place.model';
import { LandlordPlacesApiService } from '../../core/places/services/landlord-places-api.service';
import { PlaceLocationPickerComponent } from './place-location-picker.component';
import { map, startWith } from 'rxjs';

/**
 * Esta pantalla ahora cubre creación y edición real.
 * La clave arquitectónica es mantener un solo formulario y dejar que el modo
 * nazca desde la ruta y el lugar cargado.
 */
@Component({
  selector: 'app-landlord-place-form-page',
  standalone: true,
  templateUrl: './landlord-place-form.page.html',
  styleUrl: './landlord-place-form.page.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    IonButton,
    IonCard,
    IonCardContent,
    IonContent,
    IonInput,
    IonItem,
    IonNote,
    IonSpinner,
    IonText,
    IonTextarea,
    PlaceLocationPickerComponent,
  ],
})
export class LandlordPlaceFormPage {
  private readonly formBuilder = inject(FormBuilder);
  private readonly authSession = inject(AuthSessionService);
  private readonly placesApi = inject(LandlordPlacesApiService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  // placeId resuelve el modo: null = create, número válido = edit.
  readonly placeId = signal<number | null>(this.readRoutePlaceId());
  readonly loadingPlace = signal(false);
  readonly saving = signal(false);
  readonly loadErrorMessage = signal('');
  readonly submitErrorMessage = signal('');
  readonly selectedPhotos = signal<File[]>([]);
  readonly existingPhotoUrls = signal<string[]>([]);
  readonly showLocationPicker = signal(false);

  readonly mode = computed<'create' | 'edit'>(() =>
    this.placeId() ? 'edit' : 'create',
  );
  readonly pageTitle = computed(() =>
    this.mode() === 'create' ? 'Publicar un lugar' : 'Editar lugar',
  );
  readonly formSubtitle = computed(() =>
    this.mode() === 'create'
      ? 'Cargá todos los datos del lugar y una primera galería obligatoria.'
      : 'Revisá el lugar existente, corregí sus datos y entrá a sus reservas desde acá.',
  );
  readonly flowLabel = computed(() =>
    this.mode() === 'create' ? 'Datos + fotos' : 'Edición + reservas',
  );
  readonly submitButtonLabel = computed(() =>
    this.saving()
      ? this.mode() === 'create'
        ? 'Guardando...'
        : 'Actualizando...'
      : this.mode() === 'create'
        ? 'Guardar lugar'
        : 'Guardar cambios',
  );

  // Este formulario junta datos visuales del usuario, pero todavía NO construye el payload final.
  // La traducción a tipos y reglas de negocio ocurre en buildDraft().
  readonly form = this.formBuilder.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(4)]],
    description: ['', [Validators.required, Validators.minLength(10)]],

    guests: ['', [Validators.required]],
    beds: ['', [Validators.required]],
    bathrooms: ['', [Validators.required]],
    rooms: ['', [Validators.required]],

    hasWifi: [true],
    hasParking: [false],
    parkingSlots: ['0', [Validators.required]],

    pricePerNight: ['', [Validators.required]],
    cleaningCost: ['', [Validators.required]],

    city: ['', [Validators.required, Validators.minLength(2)]],
    latitude: ['', [Validators.required]],
    longitude: ['', [Validators.required]],
  });

  // Convertimos valueChanges en signals para que el template lea coordenadas estables.
  // Así evitamos recalcular métodos en cada ciclo y solo re-renderizamos el mapa cuando cambia lat/lng.
  readonly currentLatitude = toSignal(
    this.form.controls.latitude.valueChanges.pipe(
      startWith(this.form.controls.latitude.getRawValue()),
      map((value) => this.readOptionalNumber(value)),
    ),
    { initialValue: this.readOptionalNumber(this.form.controls.latitude.getRawValue()) },
  );
  readonly currentLongitude = toSignal(
    this.form.controls.longitude.valueChanges.pipe(
      startWith(this.form.controls.longitude.getRawValue()),
      map((value) => this.readOptionalNumber(value)),
    ),
    { initialValue: this.readOptionalNumber(this.form.controls.longitude.getRawValue()) },
  );
  readonly hasSelectedCoordinates = computed(
    () => this.currentLatitude() !== null && this.currentLongitude() !== null,
  );
  readonly locationPickerToggleLabel = computed(() => {
    if (this.showLocationPicker()) {
      return 'Ocultar mapa';
    }

    return this.hasSelectedCoordinates() ? 'Ajustar en el mapa' : 'Abrir mapa';
  });

  constructor() {
    // Si la ruta trae un ID, intentamos hidratar el formulario apenas se crea la página.
    if (this.mode() === 'edit') {
      void this.loadPlaceForEdit();
    }
  }

  async submit(): Promise<void> {
    if (this.loadingPlace()) {
      this.submitErrorMessage.set('Esperá a que termine la carga del lugar antes de guardar.');
      return;
    }

    // Primero protegemos la experiencia local: no salimos a red si faltan obligatorios básicos.
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      this.submitErrorMessage.set('Completá los campos obligatorios antes de guardar.');
      return;
    }

    if (!this.hasRequiredPhotos()) {
      this.submitErrorMessage.set(this.buildPhotoRequirementMessage());
      return;
    }

    this.saving.set(true);
    this.submitErrorMessage.set('');

    try {
      // Crear lugar es una operación autenticada; restauramos sesión antes de seguir.
      await this.authSession.ensureRestored();

      const session = this.authSession.session();

      if (!session) {
        throw new Error('La sesión no está disponible para crear lugares.');
      }

      // buildDraft transforma strings del form en números/booleanos correctos para dominio.
      const draft = this.buildDraft();

      // El servicio se ocupa del proceso real: crear/actualizar y luego intentar subir fotos nuevas.
      const result = this.mode() === 'create'
        ? await this.placesApi.createPlace(session, draft)
        : await this.placesApi.updatePlace(session, this.placeId() ?? 0, draft);

      // Si hubo warning por fotos, lo priorizamos; si no, armamos el mensaje de éxito completo.
      const uploadMessage =
        result.warningMessage ||
        (this.mode() === 'create'
          ? `${result.place.name} se publicó correctamente con ${result.uploadedPhotos} foto(s).`
          : `${result.place.name} se actualizó correctamente${
              result.uploadedPhotos > 0
                ? ` y sumó ${result.uploadedPhotos} foto(s) nueva(s).`
                : '.'
            }`);

      // Volvemos al listado con mensaje contextual para que el usuario entienda qué pasó.
      await this.router.navigateByUrl('/app/lugares', {
        replaceUrl: true,
        state: { message: uploadMessage },
      });
    } catch (error) {
      // Todo error se presenta como mensaje simple en la misma pantalla.
      this.submitErrorMessage.set(
        error instanceof Error ? error.message : 'No se pudo guardar el lugar.',
      );
    } finally {
      this.saving.set(false);
    }
  }

  goBack(): Promise<boolean> {
    // Cancelar vuelve al listado sin mutar nada.
    return this.router.navigateByUrl('/app/lugares');
  }

  onPhotosSelected(event: Event): void {
    // El input file entrega FileList; lo convertimos a array porque signals y dominio trabajan mejor así.
    const input = event.target as HTMLInputElement | null;
    const files = Array.from(input?.files ?? []);

    this.selectedPhotos.set(files);
  }

  async retryLoadPlace(): Promise<void> {
    await this.loadPlaceForEdit();
  }

  onParkingChanged(event: Event): void {
    // Si el usuario apaga parqueo, reseteamos cupos para no enviar un valor incoherente escondido.
    const checked = (event.target as HTMLInputElement | null)?.checked ?? false;

    if (!checked) {
      this.form.controls.parkingSlots.setValue('0');
    }
  }

  onMapCoordinatesChanged(coordinates: {
    latitude: number;
    longitude: number;
  }): void {
    // El mapa es una fuente de verdad interactiva: cada toque escribe coordenadas legibles en el form.
    this.form.controls.latitude.setValue(coordinates.latitude.toFixed(6));
    this.form.controls.longitude.setValue(coordinates.longitude.toFixed(6));
  }

  toggleLocationPicker(): void {
    // Leaflet es costoso en móvil. Lo montamos solo cuando el usuario necesita ajustar el punto.
    this.showLocationPicker.update((currentValue) => !currentValue);
  }

  async goToReservations(): Promise<void> {
    const placeId = this.placeId();

    if (!placeId) {
      return;
    }

    await this.router.navigate([`/app/lugares/${placeId}/reservas`], {
      state: {
        placeName: this.toText(this.form.controls.name.getRawValue()) || 'Lugar seleccionado',
        returnUrl: `/app/lugares/${placeId}/editar`,
      },
    });
  }

  private buildDraft(): LandlordPlaceDraft {
    // getRawValue devuelve todos los campos del formulario, incluso los deshabilitados si existieran.
    const value = this.form.getRawValue();

    const hasParking = Boolean(value.hasParking);

    // Si no hay parqueo, el dominio recibe 0 para que el payload sea coherente.
    const parkingSlots = hasParking
      ? this.readNumber(value.parkingSlots, 'cantidad de vehículos')
      : 0;

    // Defensa de negocio local: no tiene sentido declarar parqueo con cero espacios.
    if (hasParking && parkingSlots <= 0) {
      throw new Error(
        'Si el lugar tiene parqueo, la cantidad de vehículos debe ser mayor a cero.',
      );
    }

    return {
      // Las fotos viven fuera del FormGroup porque el navegador maneja files aparte del texto.
      photos: this.selectedPhotos(),

      // En este bloque convertimos strings del formulario a nombres/valores semánticos del draft.
      name: this.toText(value.name),
      description: this.toText(value.description),

      guests: this.readNumber(value.guests, 'cantidad de personas'),
      beds: this.readNumber(value.beds, 'camas'),
      bathrooms: this.readNumber(value.bathrooms, 'baños'),
      rooms: this.readNumber(value.rooms, 'habitaciones'),

      hasWifi: Boolean(value.hasWifi),
      parkingSlots,

      pricePerNight: this.readNumber(value.pricePerNight, 'precio por noche'),
      cleaningCost: this.readNumber(value.cleaningCost, 'costo de limpieza'),

      city: this.toText(value.city),
      latitude: this.readNumber(value.latitude, 'latitud'),
      longitude: this.readNumber(value.longitude, 'longitud'),
    };
  }

  private readNumber(raw: unknown, label: string): number {
    // Paso intermedio clave: limpiar texto antes de interpretar número.
    const text = this.toText(raw);
    const normalized = Number.parseFloat(text);

    // Si parseFloat falla, devolvemos un error con contexto del campo para ayudar a corregir rápido.
    if (!Number.isFinite(normalized)) {
      throw new Error(`Revisá el campo ${label}: debe ser un número válido.`);
    }

    return normalized;
  }

  private async loadPlaceForEdit(): Promise<void> {
    const placeId = this.placeId();

    if (!placeId) {
      return;
    }

    this.loadingPlace.set(true);
    this.loadErrorMessage.set('');

    try {
      await this.authSession.ensureRestored();

      const session = this.authSession.session();

      if (!session) {
        throw new Error('La sesión no está disponible para cargar el lugar a editar.');
      }

      const place = await this.placesApi.getPlaceById(session, placeId);
      this.prefillForm(place);
    } catch (error) {
      this.loadErrorMessage.set(
        error instanceof Error ? error.message : 'No se pudo cargar el lugar a editar.',
      );
    } finally {
      this.loadingPlace.set(false);
    }
  }

  private prefillForm(place: LandlordPlace): void {
    // patchValue permite reutilizar el mismo formulario sin depender del orden de las claves.
    this.form.patchValue({
      name: place.name,
      description: place.description,
      guests: this.formatNumber(place.guests),
      beds: this.formatNumber(place.beds),
      bathrooms: this.formatNumber(place.bathrooms),
      rooms: this.formatNumber(place.rooms),
      hasWifi: place.hasWifi,
      hasParking: place.hasParking,
      parkingSlots: this.formatNumber(place.parkingSlots),
      pricePerNight: this.formatNumber(place.pricePerNight),
      cleaningCost: this.formatNumber(place.cleaningCost),
      city: place.city,
      latitude: this.formatNumber(place.latitude),
      longitude: this.formatNumber(place.longitude),
    });

    this.existingPhotoUrls.set(
      place.photos.length > 0 ? place.photos : place.imageUrl ? [place.imageUrl] : [],
    );
  }

  private hasRequiredPhotos(): boolean {
    if (this.selectedPhotos().length > 0) {
      return true;
    }

    return this.mode() === 'edit' && this.existingPhotoUrls().length > 0;
  }

  private buildPhotoRequirementMessage(): string {
    return this.mode() === 'create'
      ? 'Agregá al menos una foto antes de publicar el lugar.'
      : 'Este lugar no tiene fotos guardadas. Sumá al menos una foto antes de guardar.';
  }

  private readRoutePlaceId(): number | null {
    const rawId = this.route.snapshot.paramMap.get('id');
    const parsedId = Number.parseInt(rawId ?? '', 10);

    return Number.isFinite(parsedId) && parsedId > 0 ? parsedId : null;
  }

  private readOptionalNumber(raw: unknown): number | null {
    const text = this.toText(raw);

    if (!text) {
      return null;
    }

    const normalized = Number.parseFloat(text);
    return Number.isFinite(normalized) ? normalized : null;
  }

  private formatNumber(value: number): string {
    return Number.isFinite(value) ? `${value}` : '';
  }

  private toText(value: unknown): string {
    // Normalización centralizada para evitar trim repetidos en todo el archivo.
    return value === null || value === undefined ? '' : String(value).trim();
  }
}
