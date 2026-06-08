import '../config/app_environment.dart';

class PlaceModel {
  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.imageUrl,
    required this.galleryUrls,
    required this.capacity,
    required this.beds,
    required this.baths,
    required this.rooms,
    required this.hasWifi,
    required this.parkingSpots,
    required this.pricePerNight,
    required this.cleaningCost,
    required this.hostName,
    required this.latitude,
    required this.longitude,
    required this.rawData,
  });

  final int id;
  final String name;
  final String description;
  final String city;
  final String imageUrl;
  final List<String> galleryUrls;
  final int capacity;
  final int beds;
  final int baths;
  final int rooms;
  final bool hasWifi;
  final int parkingSpots;
  final double pricePerNight;
  final double cleaningCost;
  final String hostName;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> rawData;

  String get capacityLabel => '$capacity huéspedes';
  String get priceLabel =>
      pricePerNight <= 0 ? 'Precio no disponible' : 'Bs. ${pricePerNight.toStringAsFixed(2)} / noche';
  String get wifiLabel => hasWifi ? 'Wi-Fi disponible' : 'Sin Wi-Fi informado';
  String get parkingLabel => parkingSpots > 0
      ? 'Parqueo para $parkingSpots vehículo${parkingSpots == 1 ? '' : 's'}'
      : 'Sin parqueo informado';

  factory PlaceModel.fromJson(
    Map<String, dynamic> json, {
    String? preferredBaseUrl,
  }) {
    final photos = _extractPhotos(json, preferredBaseUrl: preferredBaseUrl);
    final host = _extractHost(json);

    return PlaceModel(
      id: _readInt(json['id']),
      name: _readString(json['nombre'] ?? json['name'], fallback: 'Lugar sin nombre'),
      description: _readString(
        json['descripcion'] ?? json['description'],
        fallback: 'Sin descripción disponible.',
      ),
      city: _readString(json['ciudad'] ?? json['city'], fallback: 'Ciudad no informada'),
      imageUrl: photos.isEmpty ? '' : photos.first,
      galleryUrls: photos,
      capacity: _readInt(json['cantPersonas'] ?? json['capacidad']),
      beds: _readInt(json['cantCamas']),
      baths: _readInt(json['cantBanios']),
      rooms: _readInt(json['cantHabitaciones']),
      hasWifi: _readBool(json['tieneWifi']),
      parkingSpots: _readInt(json['cantVehiculosParqueo']),
      pricePerNight: _readDouble(json['precioNoche']),
      cleaningCost: _readDouble(json['costoLimpieza']),
      hostName: host,
      latitude: _readDouble(json['latitud']),
      longitude: _readDouble(json['longitud']),
      rawData: json,
    );
  }

  static List<String> _extractPhotos(
    Map<String, dynamic> json, {
    String? preferredBaseUrl,
  }) {
    final photos = <String>[];
    final directCandidate = json['foto'] ?? json['imagen'] ?? json['image'];
    if (directCandidate != null && '$directCandidate'.trim().isNotEmpty) {
      photos.add(
        AppEnvironment.resolveAssetUrl(
          '$directCandidate'.trim(),
          preferredBaseUrl: preferredBaseUrl,
        ),
      );
    }

    final photoList = json['fotos'];
    if (photoList is List) {
      for (final item in photoList) {
        if (item is String && item.trim().isNotEmpty) {
          photos.add(
            AppEnvironment.resolveAssetUrl(
              item.trim(),
              preferredBaseUrl: preferredBaseUrl,
            ),
          );
        }

        if (item is Map) {
          final mapped = Map<String, dynamic>.from(item);
          final path = _readString(mapped['url'] ?? mapped['foto'] ?? mapped['path']);
          if (path.isNotEmpty) {
            photos.add(
              AppEnvironment.resolveAssetUrl(
                path,
                preferredBaseUrl: preferredBaseUrl,
              ),
            );
          }
        }
      }
    }

    return photos.toSet().toList();
  }

  static String _extractHost(Map<String, dynamic> json) {
    final owner = json['arrendatario'];
    if (owner is Map) {
      final mapped = Map<String, dynamic>.from(owner);
      return _readString(
        mapped['nombrecompleto'] ?? mapped['nombre'] ?? mapped['name'],
        fallback: 'Anfitrión no informado',
      );
    }

    return _readString(json['anfitrion'], fallback: 'Anfitrión no informado');
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

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }

    final normalized = '$value'.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'si';
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value == null ? '' : '$value'.trim();
    return text.isEmpty ? fallback : text;
  }
}
