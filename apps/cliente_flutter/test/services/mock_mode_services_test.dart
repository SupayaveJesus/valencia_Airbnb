import 'package:flutter_test/flutter_test.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/services/auth_service.dart';
import 'package:practico_final/services/places_service.dart';
import 'package:practico_final/services/reservations_service.dart';

void main() {
  group('Modo mock de contingencia', () {
    test(
      'permite registrar y luego loguear un usuario creado en la demo',
      () async {
        final authService = AuthService();
        final email = 'nuevo.mock@test.com';

        final registerResult = await authService.register(
          fullName: 'Nuevo Cliente Mock',
          email: email,
          password: '654321',
          phone: '7777777',
        );

        expect(registerResult.isSuccess, isTrue);
        expect(registerResult.isAuthenticated, isFalse);

        final session = await authService.login(
          email: email,
          password: '654321',
        );

        expect(session.hasToken, isTrue);
        expect(session.email, email);
      },
    );

    test(
      'cubre búsqueda, detalle y reserva dentro del flujo cliente',
      () async {
        final authService = AuthService();
        final placesService = PlacesService();
        final reservationsService = ReservationsService();

        final user = await authService.login(
          email: 'demo@stayhub.com',
          password: '123456',
        );

        final filters = SearchFilters(
          city: 'Santa Cruz',
          guests: 1,
          checkIn: DateTime(2026, 6, 20),
          checkOut: DateTime(2026, 6, 22),
        );

        final results = await placesService.searchPlaces(filters);
        expect(results, isNotEmpty);

        final detail = await placesService.getPlaceById(results.first.id);
        expect(detail.name, isNotEmpty);

        final created = await reservationsService.createReservation(
          user: user,
          place: detail,
          filters: filters,
        );

        expect(created.id, greaterThan(0));

        final reservations = await reservationsService.getClientReservations(
          user,
        );
        expect(reservations.any((item) => item.id == created.id), isTrue);
      },
    );
  });
}
