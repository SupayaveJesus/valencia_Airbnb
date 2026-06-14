import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:practico_final/config/app_theme.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/providers/places_provider.dart';
import 'package:practico_final/screens/advanced_search_screen.dart';

void main() {
  testWidgets('expone el contexto normal de busqueda en la vista avanzada', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlacesProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdvancedSearchScreen(
            initialFilters: SearchFilters(
              city: 'Santa Cruz',
              guests: 3,
              checkIn: DateTime(2026, 6, 8),
              checkOut: DateTime(2026, 6, 10),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ciudad'), findsOneWidget);
    expect(find.text('Llegada'), findsOneWidget);
    expect(find.text('Salida'), findsOneWidget);
    expect(find.text('Huéspedes'), findsOneWidget);
    expect(find.text('Filtros avanzados'), findsOneWidget);
    expect(find.text('08/06/2026'), findsOneWidget);
    expect(find.text('10/06/2026'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
