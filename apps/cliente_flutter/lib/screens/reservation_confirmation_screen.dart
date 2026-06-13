import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place_model.dart';
import '../models/reservation_quote.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import '../providers/reservations_provider.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'reservations_screen.dart';

/// Pantalla puente entre "quiero reservar" y "la reserva quedó creada".
///
/// Flujo que defiende esta vista:
/// 1. recibe lugar + filtros + usuario desde la búsqueda/detalle,
/// 2. calcula una cotización local para mostrar exactamente qué se cobrará,
/// 3. delega la confirmación al provider,
/// 4. si la API responde bien, reemplaza la ruta por `ReservationsScreen`.
class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({
    super.key,
    required this.place,
    required this.filters,
    required this.user,
  });

  final PlaceModel place;
  final SearchFilters filters;
  final UserSession user;

  @override
  Widget build(BuildContext context) {
    // La cotización se calcula en build porque depende solo de datos inmutables
    // de entrada. No necesita estado propio ni request previa para explicarse.
    final quote = ReservationQuote.fromPlaceAndFilters(
      place: place,
      filters: filters,
    );
    final provider = context.watch<ReservationsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar reserva')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(place.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${filters.checkInApi} → ${filters.checkOutApi} · ${filters.guests} huésped(es)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            MinimalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen económico',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _PriceRow(
                    label: '${quote.nights} noche(s) x ${place.priceLabel}',
                    amount: quote.nightsSubtotal,
                  ),
                  _PriceRow(label: 'Limpieza', amount: quote.cleaningFee),
                  _PriceRow(label: 'Servicio (10%)', amount: quote.serviceFee),
                  const Divider(height: 32),
                  _PriceRow(
                    label: 'Total',
                    amount: quote.total,
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            MinimalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qué se envía a la API',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La confirmación envía lugar_id, cliente_id, fechas y precios desglosados. Si la API responde bien, este flujo redirige a “Mis reservas” para que la persona vea la reserva recién creada dentro de su historial real.',
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Error real del backend: ${provider.errorMessage}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Confirmar reserva',
              icon: Icons.check_circle_outline,
              isLoading: provider.isLoading,
              onPressed: () async {
                // Secuencia real del CTA:
                // - limpia feedback viejo,
                // - llama al provider,
                // - si falla, la pantalla se queda acá y muestra error,
                // - si funciona, redirige al historial para validar el alta.
                provider.clearFeedback();
                final success = await context
                    .read<ReservationsProvider>()
                    .createReservation(
                      user: user,
                      place: place,
                      filters: filters,
                    );

                if (!context.mounted || !success) {
                  return;
                }

                // `pushReplacement` evita volver a una confirmación ya consumida
                // con el botón back. UX: después del éxito, el siguiente paso es
                // revisar el historial real, no reenviar accidentalmente el alta.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    // Componente visual mínimo para mantener consistente el desglose de precios
    // sin duplicar estilos entre subtotales y total general.
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasize ? 17 : 15,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('Bs. ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
