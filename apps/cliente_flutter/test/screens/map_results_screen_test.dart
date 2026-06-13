import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:practico_final/config/app_theme.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/screens/map_results_screen.dart';

void main() {
  testWidgets(
    'muestra atribucion y lugar seleccionado con coordenadas validas',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: MapResultsScreen(
            cityLabel: 'Santa Cruz',
            filters: SearchFilters(
              city: 'Santa Cruz',
              guests: 2,
              checkIn: DateTime(2026, 6, 8),
              checkOut: DateTime(2026, 6, 10),
            ),
            results: [
              _place(
                id: 1,
                name: 'Departamento Equipetrol',
                latitude: -17.7635,
                longitude: -63.1822,
              ),
              _place(
                id: 2,
                name: 'Loft Urubó',
                latitude: -17.7512,
                longitude: -63.2145,
              ),
            ],
          ),
        ),
      );

      // Protege la convivencia entre mapa, selector y CTA del detalle cuando la
      // búsqueda sí trae coordenadas que sirven para renderizar marcadores.
      expect(find.text('Vista de lista'), findsOneWidget);
      expect(find.text('Departamento Equipetrol'), findsOneWidget);
      expect(find.text('2 huéspedes'), findsOneWidget);
      expect(find.text('Parqueo para 1 vehículo'), findsOneWidget);
      expect(find.text('Bs. 30.00 / noche'), findsOneWidget);
      expect(
        find.text('Map data © OpenStreetMap contributors'),
        findsOneWidget,
      );
      expect(find.text('Ver detalle del lugar'), findsOneWidget);
    },
  );

  testWidgets('explica cuando no hay coordenadas validas', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: MapResultsScreen(
          cityLabel: 'Santa Cruz',
          results: [
            _place(id: 1, name: 'Lugar sin mapa', latitude: 0, longitude: 0),
          ],
        ),
      ),
    );

    // Cuando la API devuelve ubicaciones vacías o inválidas, la pantalla debe
    // seguir guiando al usuario sin dejarlo atrapado en un mapa roto.
    expect(find.text('Resultados sin coordenadas válidas'), findsOneWidget);
    expect(find.text('Volver a la lista'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.lightTheme, home: child);
  }
}

PlaceModel _place({
  required int id,
  required String name,
  required double latitude,
  required double longitude,
}) {
  return PlaceModel(
    id: id,
    name: name,
    description: 'Descripción breve para testing.',
    city: 'Santa Cruz',
    imageUrl: '',
    galleryUrls: const [],
    capacity: 2,
    beds: 1,
    baths: 1,
    rooms: 1,
    hasWifi: true,
    parkingSpots: 1,
    pricePerNight: 30,
    cleaningCost: 5,
    hostName: 'Anfitrión real',
    latitude: latitude,
    longitude: longitude,
    rawData: const {},
  );
}
