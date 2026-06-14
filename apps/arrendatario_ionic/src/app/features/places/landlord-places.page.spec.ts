import { signal, WritableSignal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { LandlordSession } from '../../core/auth/models/landlord-session.model';
import { LandlordPlace } from '../../core/places/models/landlord-place.model';
import { LandlordPlacesApiService } from '../../core/places/services/landlord-places-api.service';
import { LandlordPlacesPage } from './landlord-places.page';

describe('LandlordPlacesPage', () => {
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
      'listByLandlord',
    ]);

    router = jasmine.createSpyObj<Router>('Router', [
      'navigate',
      'navigateByUrl',
      'getCurrentNavigation',
    ]);
    router.getCurrentNavigation.and.returnValue(null);

    await TestBed.configureTestingModule({
      imports: [LandlordPlacesPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: LandlordPlacesApiService, useValue: placesApi },
        { provide: Router, useValue: router },
      ],
    }).compileComponents();
  });

  it('muestra la primera foto cuando el lugar ya trae una imagen', async () => {
    placesApi.listByLandlord.and.resolveTo([
      new LandlordPlace(
        1,
        'Casa del Lago',
        'Cochabamba',
        'Vista abierta al lago.',
        320,
        4,
        'http://cdn.test/fotos/lago.jpg',
        {},
      ),
    ]);

    const fixture = TestBed.createComponent(LandlordPlacesPage);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const image = fixture.nativeElement.querySelector('.place-photo__image') as HTMLImageElement | null;
    const placeholder = fixture.nativeElement.querySelector('.place-photo__placeholder');

    expect(image).not.toBeNull();
    expect(image?.src).toContain('lago.jpg');
    expect(image?.alt).toContain('Casa del Lago');
    expect(placeholder).toBeNull();
  });

  it('muestra un bloque sólido de respaldo cuando el lugar no tiene foto', async () => {
    placesApi.listByLandlord.and.resolveTo([
      new LandlordPlace(
        2,
        'Departamento Urbano',
        'La Paz',
        'Cerca del teleférico.',
        210,
        2,
        '',
        {},
      ),
    ]);

    const fixture = TestBed.createComponent(LandlordPlacesPage);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const placeholder = fixture.nativeElement.querySelector('.place-photo__placeholder') as HTMLElement | null;
    const hint = fixture.nativeElement.querySelector('.place-photo__hint') as HTMLElement | null;
    const image = fixture.nativeElement.querySelector('.place-photo__image');

    expect(placeholder).not.toBeNull();
    expect(placeholder?.textContent).toContain('DU');
    expect(hint?.textContent).toContain('Sin foto');
    expect(image).toBeNull();
  });

  it('lleva al formulario real de edición cuando el arrendatario elige un lugar', async () => {
    const place = new LandlordPlace(
      3,
      'Cabaña del Bosque',
      'Santa Cruz',
      'Cerca de senderos y con parrillero.',
      280,
      4,
      '',
      {},
    );

    placesApi.listByLandlord.and.resolveTo([place]);

    const fixture = TestBed.createComponent(LandlordPlacesPage);
    const component = fixture.componentInstance;

    fixture.detectChanges();
    await fixture.whenStable();

    await component.goToEditPlace(place);

    expect(router.navigateByUrl).toHaveBeenCalledWith('/app/lugares/3/editar');
  });

  it('expone una acción directa para abrir las reservas desde el listado', async () => {
    const place = new LandlordPlace(
      11,
      'Loft Central',
      'Cochabamba',
      'A pasos de restaurantes y cafés.',
      260,
      3,
      '',
      {},
    );

    placesApi.listByLandlord.and.resolveTo([place]);

    const fixture = TestBed.createComponent(LandlordPlacesPage);
    const component = fixture.componentInstance;

    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Ver reservas');

    await component.goToReservations(place);

    expect(router.navigate).toHaveBeenCalledWith([`/app/lugares/${place.id}/reservas`], {
      state: {
        placeName: place.name,
        returnUrl: '/app/lugares',
      },
    });
  });

  it('presenta un estado vacío más limpio cuando la cuenta todavía no tiene publicaciones', async () => {
    placesApi.listByLandlord.and.resolveTo([]);

    const fixture = TestBed.createComponent(LandlordPlacesPage);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Todavía no publicaste ningún lugar.');
    expect(text).toContain('Crear mi primer lugar');
  });
});
