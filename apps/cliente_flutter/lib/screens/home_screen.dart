import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/search_filters.dart';
import '../providers/auth_provider.dart';
import '../providers/places_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/minimal_card.dart';
import '../widgets/place_card.dart';
import '../widgets/primary_button.dart';
import 'advanced_search_screen.dart';
import 'reservations_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estos controllers mantienen sincronizados los campos visibles con el estado
  // real del formulario para poder validar y reutilizar los datos al navegar.
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _guestsController = TextEditingController(text: '1');
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void dispose() {
    // Toda pantalla que crea controllers debe liberarlos para evitar fugas de
    // memoria cuando el usuario sale de esta vista.
    _cityController.dispose();
    _guestsController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    // La fecha inicial cambia según el campo tocado: llegada usa la fecha ya
    // elegida o hoy; salida intenta arrancar un día después del check-in.
    final now = DateTime.now();
    final initialDate = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ??
              (_checkIn?.add(const Duration(days: 1)) ??
                  now.add(const Duration(days: 1))));

    final selectedDate = await showDatePicker(
      context: context,
      firstDate: isCheckIn ? now : (_checkIn ?? now),
      lastDate: DateTime(now.year + 2),
      initialDate: initialDate,
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      if (isCheckIn) {
        // Si el usuario mueve la llegada hacia adelante, invalidamos una salida
        // anterior o igual para no dejar un rango inconsistente.
        _checkIn = selectedDate;
        _checkInController.text = _formatDate(selectedDate);

        if (_checkOut != null && !_checkOut!.isAfter(selectedDate)) {
          _checkOut = null;
          _checkOutController.clear();
        }
      } else {
        _checkOut = selectedDate;
        _checkOutController.text = _formatDate(selectedDate);
      }
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  SearchFilters? _buildFilters() {
    // Este método concentra la validación para que la búsqueda simple y la
    // avanzada salgan desde la misma base de datos temporal del formulario.
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    return SearchFilters(
      city: _cityController.text.trim(),
      guests: int.tryParse(_guestsController.text.trim()) ?? 1,
      checkIn: _checkIn!,
      checkOut: _checkOut!,
    );
  }

  Future<void> _submitSearch({String? suggestedCity}) async {
    // Las búsquedas rápidas reutilizan exactamente el mismo flujo que el botón
    // principal; solo precargan la ciudad antes de construir los filtros.
    if (suggestedCity != null) {
      _cityController.text = suggestedCity;
    }

    final filters = _buildFilters();
    if (filters == null) {
      return;
    }

    await context.read<PlacesProvider>().searchSimple(filters);

    if (!mounted) {
      // Evita navegar si la pantalla ya fue destruida mientras esperaba la API.
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

  void _openAdvancedSearch() {
    // La pantalla avanzada recibe los filtros actuales para que el usuario no
    // pierda lo que ya escribió en el formulario principal.
    final filters = _buildFilters();
    if (filters == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdvancedSearchScreen(initialFilters: filters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final placesProvider = context.watch<PlacesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hola, ${authProvider.currentUser?.displayName ?? 'cliente'}',
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authProvider.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              'Encuentra tu próxima estadía',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 24),
            MinimalCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Bloque 1: filtros mínimos para disparar una búsqueda útil.
                    AppTextField(
                      label: 'Ciudad',
                      hint: 'Santa Cruz',
                      icon: Icons.location_on_outlined,
                      controller: _cityController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'La ciudad es obligatoria para buscar.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Llegada',
                            controller: _checkInController,
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () => _pickDate(isCheckIn: true),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Selecciona la llegada.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Salida',
                            controller: _checkOutController,
                            icon: Icons.calendar_month_outlined,
                            readOnly: true,
                            onTap: () => _pickDate(isCheckIn: false),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Selecciona la salida.';
                              }
                              if (_checkIn != null &&
                                  _checkOut != null &&
                                  !_checkOut!.isAfter(_checkIn!)) {
                                return 'La salida debe ser posterior.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Huéspedes',
                      controller: _guestsController,
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final guests = int.tryParse((value ?? '').trim());
                        if (guests == null || guests <= 0) {
                          return 'Ingresa una cantidad válida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Bloque 2: acciones que derivan a resultados o refinan la
                    // búsqueda sin duplicar lógica de validación.
                    PrimaryButton(
                      label: 'Buscar lugares',
                      icon: Icons.search,
                      isLoading: placesProvider.isLoading,
                      onPressed: _submitSearch,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Búsqueda avanzada',
                      icon: Icons.tune,
                      isSecondary: true,
                      onPressed: _openAdvancedSearch,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Ver mis reservas',
                      icon: Icons.receipt_long_outlined,
                      isSecondary: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReservationsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Bloque 3: accesos rápidos para la defensa; muestran cómo se puede
            // reutilizar el mismo submit desde distintos puntos de entrada.
            Text('Búsquedas rápidas', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ['Santa Cruz', 'Cochabamba', 'La Paz'].map((city) {
                return ActionChip(
                  label: Text(city),
                  onPressed: () => _submitSearch(suggestedCity: city),
                );
              }).toList(),
            ),
            if (placesProvider.results.isNotEmpty) ...[
              // Si ya hubo una búsqueda, dejamos una vista previa para no volver
              // al usuario a una pantalla vacía al regresar desde resultados.
              const SizedBox(height: 32),
              Text('Últimos resultados', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...placesProvider.results
                  .take(2)
                  .map(
                    (place) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlaceCard(place: place),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
