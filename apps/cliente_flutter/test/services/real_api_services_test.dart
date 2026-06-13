import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/reservation_model.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/models/user_session.dart';
import 'package:practico_final/services/api_client.dart';
import 'package:practico_final/services/places_service.dart';
import 'package:practico_final/services/reservations_service.dart';

void main() {
  group('Servicios orientados a API real', () {
    test('SearchFilters omite tieneWifi cuando no se pidió filtrar', () {
      final filters = _filters();

      final payload = filters.toAdvancedPayload();

      // La API interpreta la ausencia del campo como "sin filtro". Mandar un 0
      // por defecto cambiaría silenciosamente el universo de resultados.
      expect(payload.containsKey('tieneWifi'), isFalse);
      expect(payload['descripcion'], '');
    });

    test('SearchFilters distingue Wi-Fi sí y Wi-Fi no', () {
      final withWifi = _filters().copyWith(hasWifi: true);
      final withoutWifi = _filters().copyWith(hasWifi: false);

      // Este par de assertions protege la traducción exacta que espera el
      // backend cuando el usuario sí decide filtrar por conectividad.
      expect(withWifi.toAdvancedPayload()['tieneWifi'], 1);
      expect(withoutWifi.toAdvancedPayload()['tieneWifi'], 0);
    });

    test('PlacesService acepta detalle envuelto en data', () async {
      final service = PlacesService(
        apiClient: _ScriptedApiClient(
          getResult: _result(
            data: {
              'data': {'id': 10, 'nombre': 'Loft real', 'ciudad': 'Santa Cruz'},
            },
          ),
        ),
      );

      final place = await service.getPlaceById(10);

      // Algunas respuestas reales encapsulan el detalle dentro de data; el
      // servicio debe tolerarlo para no romper el detalle del lugar.
      expect(place.id, 10);
      expect(place.name, 'Loft real');
      expect(place.city, 'Santa Cruz');
    });

    test('PlacesService acepta detalle envuelto en lugar', () async {
      final service = PlacesService(
        apiClient: _ScriptedApiClient(
          getResult: _result(
            data: {
              'lugar': {
                'id': 11,
                'nombre': 'Casa jardín',
                'ciudad': 'Cochabamba',
              },
            },
          ),
        ),
      );

      final place = await service.getPlaceById(11);

      // Otras rutas devuelven el mismo recurso bajo la clave lugar. Este test
      // evita acoplar el cliente a una sola envoltura del backend.
      expect(place.id, 11);
      expect(place.name, 'Casa jardín');
      expect(place.city, 'Cochabamba');
    });

    test(
      'ReservationsService acepta reserva creada envuelta en reserva',
      () async {
        final service = ReservationsService(
          apiClient: _ScriptedApiClient(
            postResult: _result(
              data: {
                'reserva': {
                  'id': 99,
                  'lugar_id': 1,
                  'nombreLugar': 'Departamento centro',
                  'nombreCliente': 'Cliente Real',
                  'fechaInicio': '2026-06-20',
                  'fechaFin': '2026-06-22',
                  'cantidadNoches': 2,
                  'precioTotal': '65.00',
                },
              },
            ),
          ),
        );

        final reservation = await service.createReservation(
          user: _user(),
          place: _place(),
          filters: _filters(),
        );

        // La confirmación de reserva debe sobrevivir aunque el backend cambie la
        // envoltura del recurso recién creado.
        expect(reservation.id, 99);
        expect(reservation.placeId, 1);
        expect(reservation.clientName, 'Cliente Real');
        expect(reservation.total, 65);
      },
    );

    test(
      'ReservationsService acepta reserva creada envuelta en data',
      () async {
        final service = ReservationsService(
          apiClient: _ScriptedApiClient(
            postResult: _result(
              data: {
                'data': {
                  'id': 100,
                  'lugar_id': 1,
                  'nombreLugar': 'Departamento centro',
                  'nombreCliente': 'Cliente Real',
                  'fechaInicio': '2026-06-20',
                  'fechaFin': '2026-06-22',
                  'cantidadNoches': 2,
                  'precioTotal': '65.00',
                },
              },
            ),
          ),
        );

        final reservation = await service.createReservation(
          user: _user(),
          place: _place(),
          filters: _filters(),
        );

        // Misma intención que arriba, pero validando la segunda forma real que
        // ya devolvieron los endpoints del proyecto.
        expect(reservation.id, 100);
        expect(reservation.placeName, 'Departamento centro');
      },
    );

    test('ReservationsService acepta listado envuelto en value', () async {
      final service = ReservationsService(
        apiClient: _ScriptedApiClient(
          getResult: _result(
            data: {
              'value': [
                {
                  'id': 551,
                  'fechaInicio': '2026-08-01',
                  'fechaFin': '2026-08-03',
                  'precioTotal': '109.00',
                  'lugar': [
                    {
                      'id': 570,
                      'nombre': 'Departamento de Estreno en Equipetrol',
                    },
                  ],
                },
              ],
            },
          ),
        ),
      );

      final reservations = await service.getClientReservations(_user());

      // El historial debe seguir cargando aunque el backend envíe listas bajo
      // value, porque esa variación impacta directamente la pantalla de reservas.
      expect(reservations, hasLength(1));
      expect(reservations.first.id, 551);
      expect(
        reservations.first.placeName,
        'Departamento de Estreno en Equipetrol',
      );
    });

    test('ReservationModel acepta lugar serializado como lista', () {
      final reservation = ReservationModel.fromJson({
        'id': 552,
        'fechaInicio': '2026-08-10',
        'fechaFin': '2026-08-12',
        'precioTotal': '120.00',
        'lugar': [
          {'id': 571, 'nombre': 'Cabaña del lago', 'foto': 'fotos/cabana.png'},
        ],
      });

      // El modelo debe soportar la forma serializada que llega en algunos
      // listados para no perder vínculo entre reserva y lugar.
      expect(reservation.placeId, 571);
      expect(reservation.placeName, 'Cabaña del lago');
    });

    test(
      'ReservationModel calcula noches desde fechas si la API las omite',
      () {
        final reservation = ReservationModel.fromJson({
          'id': 553,
          'fechaInicio': '2026-08-10',
          'fechaFin': '2026-08-13',
          'precioTotal': '180.00',
          'lugar': {'id': 572, 'nombre': 'Loft de prueba'},
        });

        // Si la API omite cantidadNoches, la app todavía tiene que poder
        // explicar la reserva y calcular totales consistentes en pantalla.
        expect(reservation.nights, 3);
      },
    );
  });
}

SearchFilters _filters() {
  return SearchFilters(
    city: 'Santa Cruz',
    guests: 2,
    checkIn: DateTime(2026, 6, 20),
    checkOut: DateTime(2026, 6, 22),
  );
}

UserSession _user() {
  return UserSession(
    id: 7,
    email: 'cliente@real.com',
    fullName: 'Cliente Real',
    phone: '7777777',
    token: '',
    rawData: const {},
  );
}

PlaceModel _place() {
  return PlaceModel.fromJson({
    'id': 1,
    'nombre': 'Departamento centro',
    'descripcion': 'Cerca de todo',
    'ciudad': 'Santa Cruz',
    'cantPersonas': 2,
    'cantCamas': 1,
    'cantBanios': 1,
    'cantHabitaciones': 1,
    'tieneWifi': 1,
    'cantVehiculosParqueo': 0,
    'precioNoche': '30.00',
    'costoLimpieza': '5.00',
  });
}

ApiRequestResult _result({required Object? data}) {
  return ApiRequestResult(
    baseUrl: 'http://api.test',
    path: '/api/places',
    response: Response<dynamic>(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: '/api/places'),
    ),
  );
}

class _ScriptedApiClient extends ApiClient {
  _ScriptedApiClient({this.postResult, this.getResult});

  final ApiRequestResult? postResult;
  final ApiRequestResult? getResult;

  @override
  Future<ApiRequestResult> postResultToCandidates({
    required List<String> paths,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    if (postResult == null) {
      throw UnimplementedError('postResult no configurado en el test');
    }

    return postResult!;
  }

  @override
  Future<ApiRequestResult> getResultToCandidates({
    required List<String> paths,
    String? token,
  }) async {
    if (getResult == null) {
      throw UnimplementedError('getResult no configurado en el test');
    }

    return getResult!;
  }
}
