import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservations_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'place_detail_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _showInitialLoader = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await _loadReservations();

      if (!mounted) {
        return;
      }

      setState(() {
        _showInitialLoader = false;
      });
    });
  }

  Future<void> _loadReservations() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || !user.hasIdentifier) {
      return;
    }

    await context.read<ReservationsProvider>().loadClientReservations(user);
  }

  void _returnToPreviousScreen() {
    Navigator.of(context).pop();
  }

  void _openPlaceDetail(ReservationModel reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlaceDetailScreen(placePreview: _buildPlacePreview(reservation)),
      ),
    );
  }

  PlaceModel _buildPlacePreview(ReservationModel reservation) {
    final placeData = _extractMapOrFirstItem(reservation.rawData['lugar']);

    return PlaceModel.fromJson({
      ...placeData,
      'id': reservation.placeId,
      'nombre': reservation.placeName,
      'foto': reservation.placeImageUrl,
      'descripcion': placeData['descripcion'] ?? 'Ver detalle del alojamiento.',
      'ciudad': placeData['ciudad'] ?? 'Ciudad no informada',
    });
  }

  Map<String, dynamic> _extractMapOrFirstItem(Object? value) {
    if (value is List && value.isNotEmpty) {
      return _extractMapOrFirstItem(value.first);
    }

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Widget _buildReservationImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 180,
        color: const Color(0xFFF1F1F1),
        alignment: Alignment.center,
        child: const Icon(Icons.home_work_outlined, size: 48),
      );
    }

    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 180,
        color: const Color(0xFFF1F1F1),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<ReservationsProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (user == null) {
              return const Center(
                child: Text('Debes iniciar sesión otra vez.'),
              );
            }

            if (!user.hasIdentifier) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MinimalCard(
                    child: const Text(
                      'No pudimos cargar tus reservas.',
                    ),
                  ),
                ),
              );
            }

            if (_showInitialLoader ||
                (provider.isLoading && provider.reservations.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null &&
                provider.reservations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MinimalCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Reintentar',
                          onPressed: _loadReservations,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (provider.reservations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MinimalCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          size: 56,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Todavía no tienes reservas registradas.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Volver',
                          icon: Icons.arrow_back,
                          onPressed: _returnToPreviousScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: provider.reservations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final reservation = provider.reservations[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openPlaceDetail(reservation),
                    child: MinimalCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: _buildReservationImage(
                              reservation.placeImageUrl,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reservation.placeName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text('Ingreso: ${reservation.checkIn}'),
                                Text('Salida: ${reservation.checkOut}'),
                                Text(
                                  'Noches: ${reservation.nights == 0 ? '-' : reservation.nights}',
                                ),
                                Text('Cliente: ${reservation.clientName}'),
                                const SizedBox(height: 8),
                                Text(
                                  reservation.totalLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(Icons.open_in_new_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Toca para ver el detalle.'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
