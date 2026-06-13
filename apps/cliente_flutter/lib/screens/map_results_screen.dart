import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_theme.dart';
import '../models/place_model.dart';
import '../models/search_filters.dart';
import '../widgets/minimal_card.dart';
import '../widgets/place_card.dart';
import '../widgets/primary_button.dart';
import 'place_detail_screen.dart';

class MapResultsScreen extends StatefulWidget {
  const MapResultsScreen({
    super.key,
    required this.results,
    required this.cityLabel,
    this.filters,
  });

  final List<PlaceModel> results;
  final String cityLabel;
  final SearchFilters? filters;

  @override
  State<MapResultsScreen> createState() => _MapResultsScreenState();
}

class _MapResultsScreenState extends State<MapResultsScreen> {
  late final List<PlaceModel> _placesWithCoordinates;
  PlaceModel? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _placesWithCoordinates = widget.results
        .where(_hasValidCoordinates)
        .toList(growable: false);
    _selectedPlace = _placesWithCoordinates.isEmpty
        ? null
        : _placesWithCoordinates.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista de mapa'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.view_list_outlined),
            label: const Text('Vista de lista'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mapa de resultados para ${widget.cityLabel}',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_buildSummaryMessage(), style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (widget.results.isEmpty)
                Expanded(child: _buildEmptyState(theme))
              else if (_placesWithCoordinates.isEmpty)
                Expanded(child: _buildNoCoordinatesState(theme))
              else ...[
                if (_placesWithCoordinates.length != widget.results.length) ...[
                  MinimalCard(
                    child: Text(
                      'Mostramos ${_placesWithCoordinates.length} marcador(es). '
                      '${widget.results.length - _placesWithCoordinates.length} resultado(s) no aparecen en el mapa.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: Column(
                    children: [
                       Expanded(
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(24),
                           child: FlutterMap(
                            options: MapOptions(
                              initialCenter: _selectedPlace == null
                                  ? const LatLng(-17.7833, -63.1821)
                                  : _toLatLng(_selectedPlace!),
                              initialZoom: 12.5,
                              initialCameraFit:
                                  _placesWithCoordinates.length > 1
                                  ? CameraFit.bounds(
                                      bounds: LatLngBounds.fromPoints(
                                        _placesWithCoordinates
                                            .map(_toLatLng)
                                            .toList(growable: false),
                                      ),
                                      padding: const EdgeInsets.all(56),
                                    )
                                  : null,
                              onTap: (_, point) => setState(() {
                                _selectedPlace = null;
                              }),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.valencia.practicofinal.practico_final',
                              ),
                              MarkerLayer(
                                markers: _placesWithCoordinates
                                    .map(
                                      (place) => Marker(
                                        point: _toLatLng(place),
                                        width: 72,
                                        height: 72,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedPlace = place;
                                            });
                                          },
                                          child: _MarkerPin(
                                            isSelected:
                                                _selectedPlace?.id == place.id,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: _SelectedPlaceCard(
                            place: _selectedPlace,
                            filters: widget.filters,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Map data © OpenStreetMap contributors',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildSummaryMessage() {
    if (widget.results.isEmpty) {
      return 'No hay resultados para mostrar en el mapa.';
    }

    if (_placesWithCoordinates.isEmpty) {
      return 'No encontramos ubicaciones disponibles.';
    }

    return 'Toca un marcador para ver el lugar.';
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: MinimalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sin resultados', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Cuando haya resultados, aparecerán aquí.',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCoordinatesState(ThemeData theme) {
    return Center(
      child: MinimalCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados sin coordenadas válidas',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Estos resultados no tienen ubicación disponible.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Volver a la lista',
              icon: Icons.view_list_outlined,
              isSecondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasValidCoordinates(PlaceModel place) {
    final latitude = place.latitude;
    final longitude = place.longitude;

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  LatLng _toLatLng(PlaceModel place) => LatLng(place.latitude, place.longitude);
}

class _MarkerPin extends StatelessWidget {
  const _MarkerPin({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.ink),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.location_on,
          size: 16,
          color: isSelected ? Colors.white : AppTheme.ink,
        ),
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.place, required this.filters});

  final PlaceModel? place;
  final SearchFilters? filters;

  @override
  Widget build(BuildContext context) {
    if (place == null) {
      final theme = Theme.of(context);

      return MinimalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marcador no seleccionado', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Toca un marcador para ver más información.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        PlaceCard(place: place!),
        if (filters != null) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Ver detalle del lugar',
            icon: Icons.arrow_forward_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(
                    placePreview: place!,
                    filters: filters!,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
