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
  Future<void>? _loadFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _loadReservations();
  }

  Future<void> _loadReservations() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || !user.hasIdentifier) {
      return;
    }

    await context.read<ReservationsProvider>().loadClientReservations(user);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<ReservationsProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (user == null) {
              return const Center(child: Text('Debes iniciar sesión otra vez.'));
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

            if (provider.isLoading && provider.reservations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.reservations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MinimalCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
                        const SizedBox(height: 12),
                        Text(provider.errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Reintentar',
                          onPressed: () {
                            setState(() {
                              _loadFuture = _loadReservations();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (provider.reservations.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay reservas para mostrar todavía.'),
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
                      Text('Noches: ${reservation.nights == 0 ? '-' : reservation.nights}'),
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
