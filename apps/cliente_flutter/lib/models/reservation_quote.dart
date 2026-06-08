import 'place_model.dart';
import 'search_filters.dart';

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
