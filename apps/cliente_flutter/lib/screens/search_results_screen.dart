import '../config/app_environment.dart';
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
              const SizedBox(height: 8),
              Text(
                AppEnvironment.useMockServices
                    ? 'Los resultados provienen del modo mock de contingencia para sostener la demo aun si el backend falla.'
                    : 'Si la API falla, la pantalla muestra el error real devuelto por los intentos a cada endpoint. No hay datos demo.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (provider.errorMessage != null) ...[
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
                                'No encontramos lugares para $city con el contrato disponible.',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                PrimaryButton(
                  label: 'Vista de mapa',
                  icon: Icons.map_outlined,
                  isSecondary: true,
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
                const SizedBox(height: 16),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
