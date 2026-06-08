import 'package:flutter_test/flutter_test.dart';

import 'package:practico_final/main.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/search_filters.dart';

void main() {
  testWidgets('renderiza la pantalla de login', (tester) async {
    await tester.pumpWidget(const PracticoFinalApp());

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  test('arma payload simple y corrige moneda de lugar', () {
    final filters = SearchFilters(
      city: 'Santa Cruz',
      guests: 2,
      checkIn: DateTime(2026, 6, 8),
      checkOut: DateTime(2026, 6, 10),
    );

    final place = PlaceModel.fromJson({
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

    expect(filters.toSimplePayload(), {'search': 'Santa Cruz'});
    expect(filters.nights, 2);
    expect(place.priceLabel, 'Bs. 30.00 / noche');
  });
}
