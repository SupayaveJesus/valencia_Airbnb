import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/places_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/place_card.dart';
import '../widgets/primary_button.dart';
import 'map_results_screen.dart';
import 'place_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Esta pantalla no consulta sola: solo representa el estado que el provider
    // dejó listo después de la búsqueda simple o avanzada.
    final provider = context.watch<PlacesProvider>();
    final theme = Theme.of(context);
    final filters = provider.lastFilters;
    final city = filters?.city ?? 'tu búsqueda';

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resultados para $city',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (provider.errorMessage != null) ...[
                // Si hubo error pero la navegación llegó igual, lo mostramos
                // arriba para que el usuario entienda por qué no hay resultados.
                MinimalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error de búsqueda',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (provider.results.isEmpty)
                Expanded(
                  child: Center(
                    child: MinimalCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sin resultados',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage ??
                                'No encontramos lugares para $city.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Con resultados, cada tarjeta puede abrir el detalle usando los
                // filtros originales para habilitar la reserva posterior.
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: provider.results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final place = provider.results[index];
                            return PlaceCard(
                              place: place,
                              onTap: filters == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaceDetailScreen(
                                            placePreview: place,
                                            filters: filters,
                                          ),
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Vista de mapa',
                        icon: Icons.map_outlined,
                        isSecondary: true,
                        // La vista de mapa reutiliza la misma lista recibida; no
                        // dispara otra consulta ni altera el estado del provider.
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapResultsScreen(
                                results: provider.results,
                                cityLabel: city,
                                filters: filters,
                              ),
                            ),
                          );
                        },
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
}
