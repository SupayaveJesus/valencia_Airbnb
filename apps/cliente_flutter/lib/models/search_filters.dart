class SearchFilters {
  const SearchFilters({
    required this.city,
    required this.guests,
    required this.checkIn,
    required this.checkOut,
    this.description = '',
    this.beds = 0,
    this.baths = 0,
    this.rooms = 0,
    this.hasWifi,
    this.parkingSpots = 0,
    this.maxPricePerNight = 0,
  });

  final String city;
  final int guests;
  final DateTime checkIn;
  final DateTime checkOut;
  final String description;
  final int beds;
  final int baths;
  final int rooms;
  final bool? hasWifi;
  final int parkingSpots;
  final double maxPricePerNight;

  int get nights {
    final difference = checkOut.difference(checkIn).inDays;
    return difference <= 0 ? 1 : difference;
  }

  String get checkInApi => _formatApiDate(checkIn);
  String get checkOutApi => _formatApiDate(checkOut);

  SearchFilters copyWith({
    String? city,
    int? guests,
    DateTime? checkIn,
    DateTime? checkOut,
    String? description,
    int? beds,
    int? baths,
    int? rooms,
    bool? hasWifi,
    bool clearWifi = false,
    int? parkingSpots,
    double? maxPricePerNight,
  }) {
    return SearchFilters(
      city: city ?? this.city,
      guests: guests ?? this.guests,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      description: description ?? this.description,
      beds: beds ?? this.beds,
      baths: baths ?? this.baths,
      rooms: rooms ?? this.rooms,
      hasWifi: clearWifi ? null : (hasWifi ?? this.hasWifi),
      parkingSpots: parkingSpots ?? this.parkingSpots,
      maxPricePerNight: maxPricePerNight ?? this.maxPricePerNight,
    );
  }

  /// Postman muestra que la búsqueda simple usa `search`.
  Map<String, dynamic> toSimplePayload() {
    return {'search': city.trim()};
  }

  /// El PDF pide más campos y Postman confirma el shape esperado del body.
  Map<String, dynamic> toAdvancedPayload() {
    return {
      'ciudad': city.trim(),
      'descripcion': description.trim().isEmpty ? 'opcional' : description.trim(),
      'cantPersonas': guests,
      'cantCamas': beds,
      'cantBanios': baths,
      'cantHabitaciones': rooms,
      'tieneWifi': hasWifi == null ? 0 : (hasWifi! ? 1 : 0),
      'cantVehiculosParqueo': parkingSpots,
      'precioNoche': maxPricePerNight,
    };
  }

  static String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
