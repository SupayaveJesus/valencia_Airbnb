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
  // Aquí replicamos los filtros en controllers porque esta pantalla permite
  // editar cada campo antes de reconstruir un SearchFilters completo.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final TextEditingController _checkInController;
  late final TextEditingController _checkOutController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _guestsController;
  late final TextEditingController _bedsController;
  late final TextEditingController _bathsController;
  late final TextEditingController _roomsController;
  late final TextEditingController _parkingController;
  late final TextEditingController _priceController;
  late DateTime _checkIn;
  late DateTime _checkOut;
  bool? _hasWifi;

  @override
  void initState() {
    super.initState();
    // Se parte de los filtros ya elegidos en Home para que la búsqueda avanzada
    // sea una continuación del flujo y no un formulario vacío independiente.
    final filters = widget.initialFilters;
    _cityController = TextEditingController(text: filters.city);
    _checkIn = filters.checkIn;
    _checkOut = filters.checkOut;
    _checkInController = TextEditingController(text: _formatDate(_checkIn));
    _checkOutController = TextEditingController(text: _formatDate(_checkOut));
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
    // Como los controllers se crean manualmente, también se destruyen aquí.
    _cityController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
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
    // copyWith evita reconstruir el filtro desde cero y deja explícito qué
    // campos cambian en esta pantalla y cuáles se heredan del paso anterior.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final filters = widget.initialFilters.copyWith(
      city: _cityController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
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

    // pushReplacement devuelve al usuario a la misma pantalla de resultados,
    // reemplazando esta vista intermedia para que el back sea más natural.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultsScreen()),
    );
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    // En búsqueda avanzada la salida nunca puede quedar antes de la llegada,
    // por eso recalculamos automáticamente una fecha válida si hace falta.
    final now = DateUtils.dateOnly(DateTime.now());
    final firstDate = isCheckIn ? now : _checkIn;
    final currentValue = isCheckIn ? _checkIn : _checkOut;
    final fallbackDate = isCheckIn
        ? now
        : _checkIn.add(const Duration(days: 1));
    final initialDate = currentValue.isBefore(firstDate)
        ? fallbackDate
        : currentValue;

    final selectedDate = await showDatePicker(
      context: context,
      firstDate: firstDate,
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

        if (!_checkOut.isAfter(selectedDate)) {
          // Mantiene la coherencia del rango cuando cambia el check-in.
          _checkOut = selectedDate.add(const Duration(days: 1));
          _checkOutController.text = _formatDate(_checkOut);
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
              'Completá tu búsqueda',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            MinimalCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Bloque 1: datos base que toda búsqueda necesita.
                    AppTextField(
                      label: 'Ciudad',
                      controller: _cityController,
                      icon: Icons.location_on_outlined,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'La ciudad es obligatoria.'
                          : null,
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
                              if (!_checkOut.isAfter(_checkIn)) {
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
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Descripción opcional',
                      controller: _descriptionController,
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Bloque 2: refinadores opcionales para mostrar dominio de
                    // filtros sin ensuciar el flujo principal de Home.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filtros avanzados',
                        style: theme.textTheme.titleLarge,
                      ),
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
                    // Bloque 3: único punto de salida; primero valida y luego
                    // delega al provider la consulta avanzada.
                    PrimaryButton(
                      label: 'Buscar lugares',
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
    // Este helper evita repetir la misma validación numérica en cada filtro
    // cuantitativo y mantiene homogéneo el formulario.
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
