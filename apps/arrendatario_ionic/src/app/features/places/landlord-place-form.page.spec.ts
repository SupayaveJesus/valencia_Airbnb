import { signal, WritableSignal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { convertToParamMap, ActivatedRoute, Router } from '@angular/router';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { LandlordSession } from '../../core/auth/models/landlord-session.model';
import { LandlordPlace } from '../../core/places/models/landlord-place.model';
import { LandlordPlacesApiService } from '../../core/places/services/landlord-places-api.service';
import { LandlordPlaceFormPage } from './landlord-place-form.page';

describe('LandlordPlaceFormPage', () => {
  let authSession: {
    ensureRestored: jasmine.Spy<() => Promise<void>>;
    session: WritableSignal<LandlordSession | null>;
  };
  let placesApi: jasmine.SpyObj<LandlordPlacesApiService>;
  let router: jasmine.SpyObj<Router>;

  beforeEach(async () => {
    authSession = {
      ensureRestored: jasmine.createSpy('ensureRestored').and.resolveTo(),
      session: signal(new LandlordSession(9, 'demo@mail.com', 'Demo', '70000000', 'token', {})),
    };

    placesApi = jasmine.createSpyObj<LandlordPlacesApiService>('LandlordPlacesApiService', [
      'createPlace',
      'getPlaceById',
      'updatePlace',
    ]);

    router = jasmine.createSpyObj<Router>('Router', ['navigate', 'navigateByUrl']);
    router.navigate.and.resolveTo(true);
    router.navigateByUrl.and.resolveTo(true);
  });

  it('bloquea la publicación en create cuando no se seleccionó ninguna foto', async () => {
    await TestBed.configureTestingModule({
      imports: [LandlordPlaceFormPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: LandlordPlacesApiService, useValue: placesApi },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap({}) } },
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(LandlordPlaceFormPage);
    const component = fixture.componentInstance;

    component.form.patchValue({
      name: 'Casa del Lago',
      description: 'Vista abierta al lago con patio y muelle privado.',
      guests: '5',
      beds: '3',
      bathrooms: '2',
      rooms: '4',
      hasWifi: true,
      hasParking: true,
      parkingSlots: '2',
      pricePerNight: '320',
      cleaningCost: '40',
      city: 'Cochabamba',
      latitude: '-17.384000',
      longitude: '-66.159000',
    });

    await component.submit();

    expect(placesApi.createPlace).not.toHaveBeenCalled();
    expect(component.submitErrorMessage()).toBe(
      'Agregá al menos una foto antes de publicar el lugar.',
    );
  });

  it('mantiene el mapa fuera del DOM hasta que el usuario decide abrirlo', async () => {
    await TestBed.configureTestingModule({
      imports: [LandlordPlaceFormPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: LandlordPlacesApiService, useValue: placesApi },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap({}) } },
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(LandlordPlaceFormPage);
    const component = fixture.componentInstance;

    fixture.detectChanges();

    const beforeOpen = fixture.nativeElement as HTMLElement;

    expect(beforeOpen.textContent).toContain('Abrir mapa');
    expect(beforeOpen.querySelector('app-place-location-picker')).toBeNull();

    component.toggleLocationPicker();
    fixture.detectChanges();

    const afterOpen = fixture.nativeElement as HTMLElement;

    expect(afterOpen.textContent).toContain('Ocultar mapa');
    expect(afterOpen.querySelector('app-place-location-picker')).not.toBeNull();
  });

  it('ajusta el texto del disparador del mapa cuando edición ya trae coordenadas cargadas', async () => {
    const existingPlace = new LandlordPlace(
      7,
      'Casa del Lago',
      'Cochabamba',
      'Vista abierta al lago con patio y muelle privado.',
      320,
      5,
      'https://airbnbmob2.site/storage/fotos/lago-1.jpg',
      {},
      3,
      2,
      4,
      true,
      2,
      40,
      -17.384,
      -66.159,
      ['https://airbnbmob2.site/storage/fotos/lago-1.jpg'],
    );

    placesApi.getPlaceById.and.resolveTo(existingPlace);

    await TestBed.configureTestingModule({
      imports: [LandlordPlaceFormPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: LandlordPlacesApiService, useValue: placesApi },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap({ id: '7' }) } },
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(LandlordPlaceFormPage);

    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Ajustar en el mapa');
    expect(fixture.nativeElement.querySelector('app-place-location-picker')).toBeNull();
  });

  it('carga el modo edición, habilita ver reservas y actualiza sin exigir fotos nuevas si ya existen', async () => {
    const existingPlace = new LandlordPlace(
      7,
      'Casa del Lago',
      'Cochabamba',
      'Vista abierta al lago con patio y muelle privado.',
      320,
      5,
      'https://airbnbmob2.site/storage/fotos/lago-1.jpg',
      {},
      3,
      2,
      4,
      true,
      2,
      40,
      -17.384,
      -66.159,
      ['https://airbnbmob2.site/storage/fotos/lago-1.jpg'],
    );

    placesApi.getPlaceById.and.resolveTo(existingPlace);
    placesApi.updatePlace.and.resolveTo({
      place: existingPlace,
      uploadedPhotos: 0,
      warningMessage: '',
    });

    await TestBed.configureTestingModule({
      imports: [LandlordPlaceFormPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: LandlordPlacesApiService, useValue: placesApi },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap({ id: '7' }) } },
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(LandlordPlaceFormPage);
    const component = fixture.componentInstance;

    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    expect(component.mode()).toBe('edit');
    expect(component.existingPhotoUrls().length).toBe(1);
    expect(fixture.nativeElement.textContent).toContain('Ver reservas');

    await component.submit();

    expect(placesApi.updatePlace).toHaveBeenCalled();
    expect(placesApi.createPlace).not.toHaveBeenCalled();
    expect(router.navigateByUrl).toHaveBeenCalledWith('/app/lugares', {
      replaceUrl: true,
      state: { message: 'Casa del Lago se actualizó correctamente.' },
    });
  });
});
