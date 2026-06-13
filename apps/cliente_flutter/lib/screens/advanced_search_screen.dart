import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/search_filters.dart';
import '../providers/places_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'search_results_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key, required this.initialFilters});

  final SearchFilters initialFilters;

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _guestsController;
  late final TextEditingController _bedsController;
  late final TextEditingController _bathsController;
  late final TextEditingController _roomsController;
  late final TextEditingController _parkingController;
  late final TextEditingController _priceController;
  bool? _hasWifi;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _cityController = TextEditingController(text: filters.city);
    _descriptionController = TextEditingController(text: filters.description);
    _guestsController = TextEditingController(text: filters.guests.toString());
    _bedsController = TextEditingController(text: filters.beds.toString());
    _bathsController = TextEditingController(text: filters.baths.toString());
    _roomsController = TextEditingController(text: filters.rooms.toString());
    _parkingController = TextEditingController(
      text: filters.parkingSpots.toString(),
    );
    _priceController = TextEditingController(
      text: filters.maxPricePerNight == 0
          ? ''
          : filters.maxPricePerNight.toStringAsFixed(0),
    );
    _hasWifi = filters.hasWifi;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _descriptionController.dispose();
    _guestsController.dispose();
    _bedsController.dispose();
    _bathsController.dispose();
    _roomsController.dispose();
    _parkingController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final filters = widget.initialFilters.copyWith(
      city: _cityController.text.trim(),
      description: _descriptionController.text.trim(),
      guests: int.tryParse(_guestsController.text.trim()) ?? 1,
      beds: int.tryParse(_bedsController.text.trim()) ?? 0,
      baths: int.tryParse(_bathsController.text.trim()) ?? 0,
      rooms: int.tryParse(_roomsController.text.trim()) ?? 0,
      parkingSpots: int.tryParse(_parkingController.text.trim()) ?? 0,
      maxPricePerNight: double.tryParse(_priceController.text.trim()) ?? 0,
      hasWifi: _hasWifi,
      clearWifi: _hasWifi == null,
    );

    await context.read<PlacesProvider>().searchAdvanced(filters);

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlacesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Búsqueda avanzada')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Filtra con más detalle',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí ampliamos la búsqueda sin cambiar la idea del ejercicio: el formulario captura filtros legibles para la persona y luego se traduce al body real que consume la API.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            MinimalCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Ciudad',
                      controller: _cityController,
                      icon: Icons.location_on_outlined,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'La ciudad es obligatoria.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Descripción opcional',
                      controller: _descriptionController,
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Huéspedes',
                      _guestsController,
                      Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Camas',
                      _bedsController,
                      Icons.bed_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Baños',
                      _bathsController,
                      Icons.bathtub_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Habitaciones',
                      _roomsController,
                      Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Parqueos',
                      _parkingController,
                      Icons.local_parking_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      'Precio máximo por noche',
                      _priceController,
                      Icons.attach_money_outlined,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool?>(
                      initialValue: _hasWifi,
                      decoration: const InputDecoration(labelText: 'Wi-Fi'),
                      items: const [
                        DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('No filtrar'),
                        ),
                        DropdownMenuItem<bool?>(value: true, child: Text('Sí')),
                        DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('No'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _hasWifi = value),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Buscar con filtros avanzados',
                      icon: Icons.tune,
                      isLoading: provider.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return AppTextField(
      label: label,
      controller: controller,
      icon: icon,
      keyboardType: TextInputType.number,
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) {
          return null;
        }

        final number = num.tryParse(text);
        if (number == null || number < 0) {
          return 'Ingresa un número válido.';
        }

        return null;
      },
    );
  }
}
