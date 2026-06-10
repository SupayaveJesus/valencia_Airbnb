import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/reservations_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';

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
    // esta pantalla. Eso era lo que disparaba el crash en "Mis reservas".
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
                      'La API no devolvió un id de cliente en la sesión. Sin ese dato NO se puede consultar /reservas/cliente/{id}.',
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
                        const SizedBox(height: 12),
                        const Text(
                          'Para continuar con la demo, vuelve a la pantalla anterior, busca un alojamiento y confirma tu primera reserva. Así el flujo queda completo y visible.',
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

                return MinimalCard(
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
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
