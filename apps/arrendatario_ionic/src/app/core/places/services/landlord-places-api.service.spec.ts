import { TestBed } from '@angular/core/testing';

import { LandlordSession } from '../../auth/models/landlord-session.model';
import { ApiClientService } from '../../http/api-client.service';
import { LandlordPlaceDraft } from '../models/landlord-place-draft.model';
import { LandlordPlacesApiService } from './landlord-places-api.service';

describe('LandlordPlacesApiService', () => {
  let service: LandlordPlacesApiService;
  let apiClient: jasmine.SpyObj<ApiClientService>;

  const session = new LandlordSession(9, 'demo@mail.com', 'Demo', '70000000', 'token', {});

  const draft: LandlordPlaceDraft = {
    photos: [new File(['foto'], 'lugar.png', { type: 'image/png' })],
    name: 'Casa del Lago',
    description: 'Vista abierta al lago con patio y muelle privado.',
    guests: 5,
    beds: 3,
    bathrooms: 2,
    rooms: 4,
    hasWifi: true,
    parkingSlots: 2,
    pricePerNight: 320,
    cleaningCost: 40,
    city: 'Cochabamba',
    latitude: -17.384,
    longitude: -66.159,
  };

  beforeEach(() => {
    apiClient = jasmine.createSpyObj<ApiClientService>('ApiClientService', [
      'getFromCandidates',
      'postToCandidates',
      'postFormDataToCandidates',
    ]);

    TestBed.configureTestingModule({
      providers: [
        LandlordPlacesApiService,
        { provide: ApiClientService, useValue: apiClient },
      ],
    });

    service = TestBed.inject(LandlordPlacesApiService);
  });

  it('carga un lugar con los campos que el flujo de edición necesita', async () => {
    apiClient.getFromCandidates.and.resolveTo({
      baseUrl: 'https://airbnbmob2.site',
      path: '/api/lugares/7',
      body: {
        id: 7,
        nombre: 'Casa del Lago',
        descripcion: 'Vista abierta al lago con patio y muelle privado.',
        cantPersonas: 5,
        cantCamas: 3,
        cantBanios: 2,
        cantHabitaciones: 4,
        tieneWifi: 1,
        cantVehiculosParqueo: 2,
        precioNoche: '320.00',
        costoLimpieza: '40.00',
        ciudad: 'Cochabamba',
        latitud: '-17.384',
        longitud: '-66.159',
        fotos: ['/storage/fotos/lago-1.jpg'],
      },
    });

    const place = await service.getPlaceById(session, 7);

    expect(apiClient.getFromCandidates).toHaveBeenCalledWith({
      paths: ['/api/lugares/7', '/api/lugar/7'],
      token: 'token',
    });
    expect(place.id).toBe(7);
    expect(place.beds).toBe(3);
    expect(place.bathrooms).toBe(2);
    expect(place.rooms).toBe(4);
    expect(place.hasWifi).toBeTrue();
    expect(place.parkingSlots).toBe(2);
    expect(place.cleaningCost).toBe(40);
    expect(place.latitude).toBeCloseTo(-17.384, 3);
    expect(place.longitude).toBeCloseTo(-66.159, 3);
    expect(place.photos.length).toBe(1);
  });

  it('usa el guardado con id en body para actualizar y mantiene la subida de fotos nuevas', async () => {
    apiClient.postToCandidates.and.resolveTo({
      baseUrl: 'https://airbnbmob2.site',
      path: '/api/lugar',
      body: {
        id: 7,
        nombre: draft.name,
        descripcion: draft.description,
        cantPersonas: draft.guests,
        cantCamas: draft.beds,
        cantBanios: draft.bathrooms,
        cantHabitaciones: draft.rooms,
        tieneWifi: 1,
        cantVehiculosParqueo: draft.parkingSlots,
        precioNoche: '320.00',
        costoLimpieza: '40.00',
        ciudad: draft.city,
        latitud: `${draft.latitude}`,
        longitud: `${draft.longitude}`,
        fotos: ['/storage/fotos/lago-1.jpg'],
      },
    });
    apiClient.postFormDataToCandidates.and.resolveTo({
      baseUrl: 'https://airbnbmob2.site',
      path: '/api/lugar/7/foto',
      body: {},
    });

    const result = await service.updatePlace(session, 7, draft);

    expect(apiClient.postToCandidates).toHaveBeenCalledWith(
      jasmine.objectContaining({
        paths: ['/api/lugar', '/api/lugares'],
        token: 'token',
        body: jasmine.objectContaining({
          id: 7,
          nombre: 'Casa del Lago',
          arrendatario_id: 9,
        }),
      }),
    );
    expect(apiClient.postFormDataToCandidates).toHaveBeenCalledWith(
      jasmine.objectContaining({
        paths: ['/api/lugar/7/foto', '/api/lugares/7/foto'],
        token: 'token',
      }),
    );
    expect(result.place.id).toBe(7);
    expect(result.uploadedPhotos).toBe(1);
  });
});
