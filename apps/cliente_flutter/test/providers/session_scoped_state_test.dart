import 'package:flutter_test/flutter_test.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/reservation_model.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/models/user_session.dart';
import 'package:practico_final/providers/places_provider.dart';
import 'package:practico_final/providers/reservations_provider.dart';
import 'package:practico_final/services/places_service.dart';
import 'package:practico_final/services/reservations_service.dart';

void main() {
  group('Estado dependiente de sesion', () {
    test(
      'PlacesProvider limpia resultados al cerrar sesion o cambiar usuario',
      () async {
        final provider = PlacesProvider(placesService: _PlacesServiceStub());
        final firstUser = _session(id: 1, email: 'cliente1@stayhub.com');
        final secondUser = _session(id: 2, email: 'cliente2@stayhub.com');

        provider.syncSession(firstUser);

        final searched = await provider.searchSimple(_filters());

        // El proveedor debe olvidar resultados del usuario anterior para que una
        // sesión nueva no herede búsquedas ni feedback ajeno.
        expect(searched, isTrue);
        expect(provider.results, isNotEmpty);
        expect(provider.lastFilters, isNotNull);

        provider.syncSession(null);
        expect(provider.results, isEmpty);
        expect(provider.lastFilters, isNull);
        expect(provider.errorMessage, isNull);

        provider.syncSession(firstUser);
        await provider.searchSimple(_filters(city: 'La Paz'));
        expect(provider.results, isNotEmpty);

        provider.syncSession(secondUser);
        expect(provider.results, isEmpty);
        expect(provider.lastFilters, isNull);
      },
    );

    test(
      'PlacesProvider no reinicia si solo cambia un token ausente o distinto',
      () async {
        final provider = PlacesProvider(placesService: _PlacesServiceStub());
        final firstSnapshot = _session(
          id: 1,
          email: 'cliente1@stayhub.com',
          token: '',
        );
        final refreshedSnapshot = _session(
          id: 1,
          email: 'cliente1@stayhub.com',
          token: 'token-nuevo-ignorado',
        );

        provider.syncSession(firstSnapshot);
        await provider.searchSimple(_filters());

        // La identidad de negocio sigue siendo la misma aunque cambie la forma
        // de autenticación; perder resultados aquí degradaría la experiencia.
        expect(provider.results, isNotEmpty);

        provider.syncSession(refreshedSnapshot);
        expect(provider.results, isNotEmpty);
        expect(provider.lastFilters, isNotNull);
      },
    );

    test(
      'ReservationsProvider limpia reservas y feedback al cambiar sesion',
      () async {
        final provider = ReservationsProvider(
          reservationsService: _ReservationsServiceStub(),
        );
        final firstUser = _session(id: 1, email: 'cliente1@stayhub.com');
        final secondUser = _session(id: 2, email: 'cliente2@stayhub.com');

        provider.syncSession(firstUser);

        final created = await provider.createReservation(
          user: firstUser,
          place: _place(),
          filters: _filters(),
        );

        // Reserva creada y feedback visible solo pertenecen a la sesión que la
        // originó; si no se limpian, se mezcla historial entre usuarios.
        expect(created, isTrue);
        expect(provider.reservations, isNotEmpty);
        expect(provider.lastCreatedReservation, isNotNull);

        provider.syncSession(secondUser);
        expect(provider.reservations, isEmpty);
        expect(provider.lastCreatedReservation, isNull);
        expect(provider.errorMessage, isNull);

        provider.syncSession(null);
        expect(provider.reservations, isEmpty);
        expect(provider.lastCreatedReservation, isNull);
      },
    );
  });
}

SearchFilters _filters({String city = 'Santa Cruz'}) {
  return SearchFilters(
    city: city,
    guests: 2,
    checkIn: DateTime(2026, 6, 20),
    checkOut: DateTime(2026, 6, 22),
  );
}

UserSession _session({
  required int id,
  required String email,
  String token = '',
}) {
  return UserSession(
    id: id,
    email: email,
    fullName: 'Cliente $id',
    phone: '700000$id',
    token: token,
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

class _PlacesServiceStub extends PlacesService {
  @override
  Future<List<PlaceModel>> searchPlaces(SearchFilters filters) async {
    return [_place()];
  }
}

class _ReservationsServiceStub extends ReservationsService {
  @override
  Future<ReservationModel> createReservation({
    required UserSession user,
    required PlaceModel place,
    required SearchFilters filters,
  }) async {
    return ReservationModel.fromJson({
      'id': 99,
      'lugar_id': place.id,
      'nombreLugar': place.name,
      'nombreCliente': user.displayName,
      'fechaInicio': filters.checkInApi,
      'fechaFin': filters.checkOutApi,
      'cantidadNoches': filters.nights,
      'precioTotal': '65.00',
    });
  }
}
