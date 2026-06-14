import { TestBed } from '@angular/core/testing';
import { convertToParamMap, ActivatedRoute, Router } from '@angular/router';

import { PlaceReservation } from '../../core/places/models/place-reservation.model';
import { PlaceReservationsApiService } from '../../core/places/services/place-reservations-api.service';
import { PlaceReservationsPage } from './place-reservations.page';

describe('PlaceReservationsPage', () => {
  let reservationsApi: jasmine.SpyObj<PlaceReservationsApiService>;
  let router: jasmine.SpyObj<Router>;

  beforeEach(async () => {
    reservationsApi = jasmine.createSpyObj<PlaceReservationsApiService>('PlaceReservationsApiService', [
      'listByPlace',
    ]);

    router = jasmine.createSpyObj<Router>('Router', ['navigateByUrl']);
    router.navigateByUrl.and.resolveTo(true);

    history.replaceState(
      {
        placeName: 'Casa del Lago',
        returnUrl: '/app/lugares/7/editar',
      },
      '',
    );

    await TestBed.configureTestingModule({
      imports: [PlaceReservationsPage],
      providers: [
        { provide: PlaceReservationsApiService, useValue: reservationsApi },
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap({ id: '7' }) } },
        },
      ],
    }).compileComponents();
  });

  it('muestra cada reserva con los datos clave que el arrendatario necesita revisar', async () => {
    reservationsApi.listByPlace.and.resolveTo([
      new PlaceReservation(
        15,
        '2026-06-10',
        '2026-06-14',
        1450,
        100,
        1200,
        150,
        'María Pérez',
        'https://cdn.test/lugar.jpg',
        {},
      ),
    ]);

    const fixture = TestBed.createComponent(PlaceReservationsPage);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Casa del Lago');
    expect(text).toContain('Lugar #7');
    expect(text).toContain('Reserva #15');
    expect(text).toContain('Cliente: María Pérez');
    expect(text).toContain('4 noches');
    expect(text).toContain('Llegada: 2026-06-10');
    expect(text).toContain('Salida: 2026-06-14');
    expect(text).toContain('Bs. 1450.00');
    expect(text).toContain('Volver a mis lugares');
  });

  it('usa un mensaje de estado vacío más presentable cuando no hay reservas', async () => {
    reservationsApi.listByPlace.and.resolveTo([]);

    const fixture = TestBed.createComponent(PlaceReservationsPage);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Aún no hay reservas registradas para este lugar.');
    expect(text).not.toContain('devueltas por la API');
  });
});
