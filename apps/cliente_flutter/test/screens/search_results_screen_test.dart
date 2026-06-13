import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:practico_final/config/app_theme.dart';
import 'package:practico_final/models/place_model.dart';
import 'package:practico_final/models/search_filters.dart';
import 'package:practico_final/providers/places_provider.dart';
import 'package:practico_final/screens/search_results_screen.dart';

void main() {
  testWidgets('renderiza la vista de mapa debajo de la lista', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PlacesProvider>.value(
        value: _FakePlacesProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchResultsScreen(),
        ),
      ),
    );

    final placeBottom = tester.getBottomLeft(find.text('Departamento centro'));
    final mapButtonTop = tester.getTopLeft(find.text('Vista de mapa'));

    expect(mapButtonTop.dy, greaterThan(placeBottom.dy));
  });
}

class _FakePlacesProvider extends PlacesProvider {
  @override
  List<PlaceModel> get results => [_place()];

  @override
  String? get errorMessage => null;

  @override
  bool get isLoading => false;

  @override
  SearchFilters? get lastFilters => SearchFilters(
    city: 'Santa Cruz',
    guests: 2,
    checkIn: DateTime(2026, 6, 8),
    checkOut: DateTime(2026, 6, 10),
  );
}

PlaceModel _place() {
  return PlaceModel(
    id: 1,
    name: 'Departamento centro',
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
    latitude: -17.7635,
    longitude: -63.1822,
    rawData: const {},
  );
}
