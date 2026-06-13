import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reservations_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'place_detail_screen.dart';

/// Historial de reservas del cliente autenticado.
///
/// Esta pantalla enseña el resultado final del bloque 3: consume el estado del
/// provider, pide el historial real al backend y permite saltar desde una
/// reserva ya creada hacia el detalle actualizado del alojamiento asociado.
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

    // IMPORTANTE: diferimos la primera carga al primer frame para evitar que
    // el provider haga notifyListeners() mientras Flutter todavía construye
    // esta pantalla. Así la vista arranca estable antes de pedir el historial
    // real de reservas del cliente autenticado.
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
      // Sin id de cliente NO existe endpoint de historial que podamos consultar.
      return;
    }

    await context.read<ReservationsProvider>().loadClientReservations(user);
  }

  void _returnToPreviousScreen() {
    Navigator.of(context).pop();
  }

  void _openPlaceDetail(ReservationModel reservation) {
    // La navegación no reconstruye toda la búsqueda original. Parte de la
    // reserva creada, arma una preview suficiente y deja que el detalle complete
    // el resto consultando la API si hace falta.
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

    // `rawData` guarda el payload original precisamente para este puente de
    // navegación: reutilizamos lo que ya vino con la reserva y completamos con
    // fallbacks legibles si algún campo no llegó en el listado.
    return PlaceModel.fromJson({
      ...placeData,
      'id': reservation.placeId,
      'nombre': reservation.placeName,
      'foto': reservation.placeImageUrl,
      'descripcion':
          placeData['descripcion'] ??
          'Abrí el detalle desde una reserva ya creada, así que esta tarjeta actúa como preview mientras consultamos el lugar completo en la API.',
      'ciudad': placeData['ciudad'] ?? 'Ciudad no informada',
    });
  }

  Map<String, dynamic> _extractMapOrFirstItem(Object? value) {
    // Igual que en el modelo, la relación `lugar` puede venir como lista o mapa.
    // Resolverlo acá evita romper la navegación al detalle por variaciones del
    // backend en un campo que conceptualmente representa un solo alojamiento.
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
      // Placeholder honesto: preferimos explicar ausencia de imagen antes que
      // dejar un hueco visual que parezca error silencioso.
      return Container(
        height: 180,
        color: const Color(0xFFF1F1F1),
        alignment: Alignment.center,
        child: const Icon(Icons.home_work_outlined, size: 48),
      );
    }

    // Esta preview NO es un adorno: le confirma a la persona usuaria que la
    // reserva y el detalle apuntan al mismo alojamiento antes de abrir la ficha.
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
              // Caso pedagógico importante: la sesión puede existir pero sin id.
              // En ese escenario el problema NO es visual, es contractual.
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MinimalCard(
                    child: const Text(
                      'La API no devolvió un id de cliente en la sesión. Sin ese dato NO se puede consultar /reservas/cliente/{id}.',
                    ),
                  ),
                ),
              );
            }

            if (_showInitialLoader ||
                (provider.isLoading && provider.reservations.isEmpty)) {
              // Loader inicial solo mientras todavía no existe historial para
              // mostrar. Si luego hay recarga con datos presentes, priorizamos
              // conservar la lista visible en vez de tapar toda la pantalla.
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null &&
                provider.reservations.isEmpty) {
              // Error de primera carga: como no hay contenido previo útil, la UI
              // se enfoca en explicar el fallo y ofrecer reintento explícito.
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
              // Estado vacío guiado: además de decir "no hay datos", explica qué
              // acción debe hacer la persona para poblar este historial.
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
                        const SizedBox(height: 12),
                        const Text(
                          'Vuelve a la pantalla anterior, busca un alojamiento y confirma tu primera reserva. Cuando la API la cree, este historial la mostrará en cuanto regreses.',
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

                // Cada tarjeta resume la reserva y a la vez funciona como puerta
                // de entrada al detalle del lugar asociado.
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
                                      child: Text(
                                        'Tocá la tarjeta para revisar el detalle actualizado del lugar.',
                                      ),
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
