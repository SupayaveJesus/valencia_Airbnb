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
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _guestsController = TextEditingController(text: '1');
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void dispose() {
    _cityController.dispose();
    _guestsController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initialDate = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ?? (_checkIn?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1))));

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
    if (suggestedCity != null) {
      _cityController.text = suggestedCity;
    }

    final filters = _buildFilters();
    if (filters == null) {
      return;
    }

    await context.read<PlacesProvider>().searchSimple(filters);

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

  void _openAdvancedSearch() {
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
        title: Text('Hola, ${authProvider.currentUser?.displayName ?? 'cliente'}'),
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
            Text('Encuentra tu próxima estadía', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              'La UI captura ciudad, fechas y huéspedes porque ese es el flujo del PDF. Luego Provider envía la búsqueda al service, el service prueba fallbacks y el modelo devuelve objetos listos para la UI.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            MinimalCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
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
                              if (_checkIn != null && _checkOut != null && !_checkOut!.isAfter(_checkIn!)) {
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
                          MaterialPageRoute(builder: (_) => const ReservationsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
              const SizedBox(height: 32),
              Text('Últimos resultados', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...placesProvider.results.take(2).map(
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
