import 'package:flutter_test/flutter_test.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/models/user_session.dart';
import 'package:practico_final/providers/places_provider.dart';
import 'package:practico_final/providers/reservations_provider.dart';

void main() {
  group('Estado dependiente de sesion', () {
    test(
      'PlacesProvider limpia resultados al cerrar sesion o cambiar usuario',
      () async {
        final provider = PlacesProvider();
        final firstUser = _session(id: 1, email: 'demo@stayhub.com');
        final secondUser = _session(id: 2, email: 'nuevo@stayhub.com');

        provider.syncSession(firstUser);

        final searched = await provider.searchSimple(_filters());
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
      'ReservationsProvider limpia reservas y feedback al cambiar sesion',
      () async {
        final provider = ReservationsProvider();
        final firstUser = _session(id: 1, email: 'demo@stayhub.com');
        final secondUser = _session(id: 2, email: 'nuevo@stayhub.com');

        provider.syncSession(firstUser);

        final created = await provider.createReservation(
          user: firstUser,
          place: _place(),
          filters: _filters(),
        );

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

UserSession _session({required int id, required String email}) {
  return UserSession(
    id: id,
    email: email,
    fullName: 'Cliente $id',
    phone: '700000$id',
    token: 'token-$id',
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
