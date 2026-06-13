import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/reservation_model.dart';
import 'package:practico_final/models/user_session.dart';
import 'package:practico_final/providers/auth_provider.dart';
import 'package:practico_final/providers/places_provider.dart';
import 'package:practico_final/providers/reservations_provider.dart';
import 'package:practico_final/screens/reservations_screen.dart';
import 'package:practico_final/services/auth_service.dart';
import 'package:practico_final/services/places_service.dart';
import 'package:practico_final/services/reservations_service.dart';

void main() {
  testWidgets(
    'Mis reservas muestra imagen, noches derivadas y abre detalle sin filtros',
    (tester) async {
      final authProvider = AuthProvider(authService: _AuthServiceStub());
      await authProvider.login(email: 'cliente@test.com', password: '123456');

      final reservationsProvider = ReservationsProvider(
        reservationsService: _ReservationsServiceStub(),
      );
      final placesProvider = PlacesProvider(
        placesService: _PlacesServiceStub(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ReservationsProvider>.value(
              value: reservationsProvider,
            ),
            ChangeNotifierProvider<PlacesProvider>.value(value: placesProvider),
          ],
          child: const MaterialApp(home: ReservationsScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Estas señales visibles sostienen que el listado comunica información ya
      // derivada desde la respuesta real del backend y no desde filtros previos.
      expect(find.text('Loft Equipetrol'), findsOneWidget);
      expect(find.text('Noches: 2'), findsOneWidget);
      expect(
        find.text(
          'Tocá la tarjeta para revisar el detalle actualizado del lugar.',
        ),
        findsOneWidget,
      );

      final imageWidget = tester.widget<Image>(find.byType(Image).first);
      final imageProvider = imageWidget.image as NetworkImage;

      // La URL completa confirma que el modelo recompone assets remotos como los
      // consume la UI real al dibujar una reserva.
      expect(imageProvider.url, 'http://api.test/fotos/loft.png');

      await tester.tap(find.text('Loft Equipetrol'));
      await tester.pumpAndSettle();

      // Al abrir detalle desde Mis reservas no deben arrastrarse filtros ni CTA
      // de reserva duplicada; la navegación tiene un objetivo distinto.
      expect(find.text('Detalle del lugar'), findsOneWidget);
      expect(find.text('Loft Equipetrol'), findsOneWidget);
      expect(find.text('Detalle completo del lugar'), findsOneWidget);
      expect(find.text('Reservar este lugar'), findsNothing);
    },
  );
}

class _AuthServiceStub extends AuthService {
  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    return UserSession(
      id: 9,
      email: email,
      fullName: 'Cliente real',
      phone: '70000000',
      token: '',
      rawData: const {},
    );
  }
}

class _ReservationsServiceStub extends ReservationsService {
  @override
  Future<List<ReservationModel>> getClientReservations(UserSession user) async {
    return [
      ReservationModel.fromJson({
        'id': 701,
        'fechaInicio': '2026-08-20',
        'fechaFin': '2026-08-22',
        'precioTotal': '210.00',
        'nombreCliente': user.displayName,
        'lugar': {
          'id': 31,
          'nombre': 'Loft Equipetrol',
          'foto': 'fotos/loft.png',
          'ciudad': 'Santa Cruz',
        },
      }, preferredBaseUrl: 'http://api.test'),
    ];
  }
}

class _PlacesServiceStub extends PlacesService {
  @override
  Future<PlaceModel> getPlaceById(int placeId) async {
    return PlaceModel.fromJson({
      'id': placeId,
      'nombre': 'Loft Equipetrol',
      'descripcion': 'Detalle completo del lugar',
      'ciudad': 'Santa Cruz',
      'foto': 'fotos/loft.png',
      'cantPersonas': 2,
      'cantCamas': 1,
      'cantBanios': 1,
      'cantHabitaciones': 1,
      'tieneWifi': 1,
      'cantVehiculosParqueo': 1,
      'precioNoche': '105.00',
      'costoLimpieza': '0.00',
      'arrendatario': {'nombrecompleto': 'Anfitrión real'},
    }, preferredBaseUrl: 'http://api.test');
  }
}
