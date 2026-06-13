import '../config/app_environment.dart';

/// Modelo que la UI consume para mostrar una reserva ya creada.
///
/// Su responsabilidad NO es repetir exactamente el contrato del backend, sino
/// ofrecer un formato estable para las pantallas. Por eso guarda tanto campos
/// normalizados (nombre, fechas, total, noches) como `rawData`, que conserva la
/// respuesta original para reconstruir previews o profundizar navegación luego.
class ReservationModel {
  ReservationModel({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.placeImageUrl,
    required this.clientName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.total,
    required this.rawData,
  });

  final int id;
  final int placeId;
  final String placeName;
  final String placeImageUrl;
  final String clientName;
  final String checkIn;
  final String checkOut;
  final int nights;
  final double total;
  final Map<String, dynamic> rawData;

  /// Etiqueta lista para pintar en la UI sin repetir formateo monetario.
  String get totalLabel => 'Bs. ${total.toStringAsFixed(2)}';

  factory ReservationModel.fromJson(
    Map<String, dynamic> json, {
    String? preferredBaseUrl,
  }) {
    // Este factory absorbe variaciones reales del backend.
    //
    // Qué hace: toma la respuesta HTTP y construye un objeto listo para la UI.
    // Cómo funciona: busca alias de campos (`fechaInicio`/`fecha_inicio`,
    // `precioTotal`/`total`, etc.) y relaciones que a veces llegan como mapa y
    // otras como lista. Así las pantallas no se llenan de `if` defensivos.
    final place = _extractMapOrFirstItem(json['lugar']);
    final client = _extractMap(json['cliente']);
    final checkIn = _readString(
      json['fechaInicio'] ?? json['fecha_inicio'],
      fallback: '-',
    );
    final checkOut = _readString(
      json['fechaFin'] ?? json['fecha_fin'],
      fallback: '-',
    );
    final image = _readString(
      place['foto'] ?? place['imagen'] ?? place['image'] ?? json['foto'],
    );

    return ReservationModel(
      id: _readInt(json['id']),
      placeId: _readInt(place['id'] ?? json['lugar_id']),
      placeName: _readString(
        place['nombre'] ?? json['nombreLugar'],
        fallback: 'Lugar reservado',
      ),
      placeImageUrl: AppEnvironment.resolveAssetUrl(
        image,
        preferredBaseUrl: preferredBaseUrl,
      ),
      clientName: _readString(
        client['nombrecompleto'] ?? json['nombreCliente'],
        fallback: 'Cliente',
      ),
      checkIn: checkIn,
      checkOut: checkOut,
      nights: _resolveNights(
        json['cantidadNoches'] ?? json['cantNoches'] ?? json['noches'],
        checkIn: checkIn,
        checkOut: checkOut,
      ),
      total: _readDouble(json['precioTotal'] ?? json['total']),
      rawData: json,
    );
  }

  /// El backend no siempre manda `cantidadNoches` en el listado de reservas.
  /// Cuando eso pasa, derivamos el valor desde las fechas para que la UI no
  /// muestre `-` aunque sí tenga el rango real de la estadía.
  static int _resolveNights(
    Object? rawValue, {
    required String checkIn,
    required String checkOut,
  }) {
    final explicitNights = _readInt(rawValue);
    if (explicitNights > 0) {
      return explicitNights;
    }

    final start = DateTime.tryParse(checkIn);
    final end = DateTime.tryParse(checkOut);
    if (start == null || end == null) {
      return 0;
    }

    final difference = end.difference(start).inDays;
    return difference <= 0 ? 1 : difference;
  }

  static Map<String, dynamic> _extractMap(Object? value) {
    // Normaliza cualquier variante de mapa para que el resto del parser trabaje
    // siempre con `Map<String, dynamic>`.
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static Map<String, dynamic> _extractMapOrFirstItem(Object? value) {
    // Algunas respuestas embeben la relación `lugar` dentro de una lista aunque
    // conceptualmente haya un solo lugar asociado a la reserva.
    if (value is List && value.isNotEmpty) {
      return _extractMap(value.first);
    }

    return _extractMap(value);
  }

  static int _readInt(Object? value) {
    // Convierte enteros enviados como número o string para tolerar cambios de
    // serialización entre endpoints.
    if (value is int) {
      return value;
    }

    return int.tryParse('$value') ?? 0;
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    // La UI recibe siempre un string usable, incluso cuando la API manda null,
    // espacios o directamente omite la propiedad.
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }
}
