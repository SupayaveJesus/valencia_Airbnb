import 'place_model.dart';
import 'search_filters.dart';

/// Cotización local previa a confirmar la reserva.
///
/// Este objeto existe para explicitar qué importes se muestran y luego se
/// envían a la API. La derivación vive cerca de la pantalla de confirmación
/// porque depende del lugar elegido + filtros actuales, todavía sin persistir.
class ReservationQuote {
  const ReservationQuote({
    required this.nights,
    required this.nightsSubtotal,
    required this.cleaningFee,
    required this.serviceFee,
    required this.total,
  });

  final int nights;
  final double nightsSubtotal;
  final double cleaningFee;
  final double serviceFee;
  final double total;

  factory ReservationQuote.fromPlaceAndFilters({
    required PlaceModel place,
    required SearchFilters filters,
  }) {
    // Flujo de datos: filtros -> noches; lugar -> precios base; quote ->
    // desglose visible para la persona usuaria y payload económico de la API.
    final nights = filters.nights;
    final nightsSubtotal = place.pricePerNight * nights;
    final cleaningFee = place.cleaningCost;
    final serviceFee = nightsSubtotal * 0.10;
    final total = nightsSubtotal + cleaningFee + serviceFee;

    return ReservationQuote(
      nights: nights,
      nightsSubtotal: nightsSubtotal,
      cleaningFee: cleaningFee,
      serviceFee: serviceFee,
      total: total,
    );
  }
}
