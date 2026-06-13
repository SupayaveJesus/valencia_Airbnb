import 'package:flutter_test/flutter_test.dart';

import 'package:practico_final/main.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/search_filters.dart';

void main() {
  testWidgets('renderiza la pantalla de login', (tester) async {
    await tester.pumpWidget(const PracticoFinalApp());

    // Defiende que el arranque siga llevando al flujo real de autenticación y
    // no a una pantalla residual de demo o a un atajo de desarrollo.
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

    // El payload mínimo protege la búsqueda básica que consume la API actual.
    expect(filters.toSimplePayload(), {'search': 'Santa Cruz'});

    // Las noches impactan precio y reservas; si se rompen, se distorsiona todo
    // el flujo comercial aunque la UI siga renderizando.
    expect(filters.nights, 2);

    // La etiqueta monetaria visible al cliente debe salir normalizada desde el
    // modelo para que todas las tarjetas comuniquen el mismo criterio.
    expect(place.priceLabel, 'Bs. 30.00 / noche');
  });
}
