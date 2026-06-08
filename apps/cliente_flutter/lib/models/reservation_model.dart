import '../config/app_environment.dart';

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

  String get totalLabel => 'Bs. ${total.toStringAsFixed(2)}';

  factory ReservationModel.fromJson(
    Map<String, dynamic> json, {
    String? preferredBaseUrl,
  }) {
    final place = _extractMap(json['lugar']);
    final client = _extractMap(json['cliente']);
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
      checkIn: _readString(
        json['fechaInicio'] ?? json['fecha_inicio'],
        fallback: '-',
      ),
      checkOut: _readString(
        json['fechaFin'] ?? json['fecha_fin'],
        fallback: '-',
      ),
      nights: _readInt(json['cantidadNoches'] ?? json['cantNoches'] ?? json['noches']),
      total: _readDouble(json['precioTotal'] ?? json['total']),
      rawData: json,
    );
  }

  static Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static int _readInt(Object? value) {
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
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }
}
