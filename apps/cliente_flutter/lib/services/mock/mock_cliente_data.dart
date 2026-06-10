import '../../config/app_environment.dart';
import '../../models/place_model.dart';
import '../../models/reservation_model.dart';
import '../../models/reservation_quote.dart';
import '../../models/search_filters.dart';
import '../../models/user_session.dart';

/// Banco de datos mock CENTRALIZADO del cliente.
///
/// ¿Por qué existe?
/// - porque el backend docente puede caerse justo durante la demo;
/// - porque queremos preservar el flujo completo sin romper la arquitectura;
/// - porque así el cambio queda encapsulado en la capa service y no disperso
///   por las pantallas.
///
/// IMPORTANTE:
/// - esto NO reemplaza la API real;
/// - solo actúa cuando `AppEnvironment.useMockServices == true`;
/// - para apagarlo, basta cambiar ese flag a `false`.
class MockClienteData {
  MockClienteData._();

  static final List<Map<String, dynamic>> _places = [
    {
      'id': 1,
      'nombre': 'Loft Equipetrol Ejecutivo',
      'descripcion':
          'Loft moderno para defensa académica: Wi-Fi, cocina equipada y acceso rápido a la zona empresarial.',
      'ciudad': 'Santa Cruz',
      'foto':
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
      'fotos': [
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
      ],
      'cantPersonas': 2,
      'cantCamas': 1,
      'cantBanios': 1,
      'cantHabitaciones': 1,
      'tieneWifi': true,
      'cantVehiculosParqueo': 1,
      'precioNoche': 210,
      'costoLimpieza': 35,
      'arrendatario': {'nombrecompleto': 'Carla Méndez'},
      'latitud': -17.7766,
      'longitud': -63.1951,
    },
    {
      'id': 2,
      'nombre': 'Departamento Familiar Cala Cala',
      'descripcion':
          'Espacio amplio para familias pequeñas con dos habitaciones y parqueo privado.',
      'ciudad': 'Cochabamba',
      'foto':
          'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
      'fotos': [
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
      ],
      'cantPersonas': 4,
      'cantCamas': 3,
      'cantBanios': 2,
      'cantHabitaciones': 2,
      'tieneWifi': true,
      'cantVehiculosParqueo': 1,
      'precioNoche': 320,
      'costoLimpieza': 40,
      'arrendatario': {'nombrecompleto': 'Luis Rocha'},
      'latitud': -17.3700,
      'longitud': -66.1710,
    },
    {
      'id': 3,
      'nombre': 'Studio Urbano Sopocachi',
      'descripcion':
          'Studio compacto para viajes cortos, cerca de cafés y transporte.',
      'ciudad': 'La Paz',
      'foto':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      'fotos': [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      ],
      'cantPersonas': 2,
      'cantCamas': 1,
      'cantBanios': 1,
      'cantHabitaciones': 1,
      'tieneWifi': false,
      'cantVehiculosParqueo': 0,
      'precioNoche': 180,
      'costoLimpieza': 20,
      'arrendatario': {'nombrecompleto': 'María Fernanda Quiroga'},
      'latitud': -16.5000,
      'longitud': -68.1500,
    },
  ];

  static final Map<String, Map<String, dynamic>> _registeredUsersByEmail = {
    'demo@stayhub.com': {
      'id': 101,
      'email': 'demo@stayhub.com',
      'nombrecompleto': 'Cliente Demo',
      'telefono': '70000001',
      'password': '123456',
    },
  };

  static final Map<int, List<Map<String, dynamic>>> _reservationsByClientId = {
    101: [
      {
        'id': 9001,
        'lugar_id': 1,
        'nombreLugar': 'Loft Equipetrol Ejecutivo',
        'nombreCliente': 'Cliente Demo',
        'fechaInicio': '2026-06-15',
        'fechaFin': '2026-06-18',
        'cantidadNoches': 3,
        'precioTotal': 728,
        'lugar': _places.first,
      },
    ],
  };

  static int _nextUserId = 200;
  static int _nextReservationId = 9500;

  /// Login mock con sesión coherente.
  ///
  /// Acepta las credenciales demo iniciales y también cualquier usuario creado
  /// por el registro mock durante la ejecución actual de la app.
  static UserSession login({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _registeredUsersByEmail[normalizedEmail];

    if (user == null || '${user['password']}' != password) {
      throw Exception(
        'Credenciales mock inválidas. Usa demo@stayhub.com / 123456 o inicia sesión con un usuario que hayas registrado en esta demo.',
      );
    }

    return UserSession.fromJson({
      ...user,
      'token': 'mock-token-$normalizedEmail',
      'cliente': user,
    });
  }

  /// Registro mock intencionalmente SIN login automático.
  ///
  /// Esto preserva la semántica corregida en el flujo real: registrar no implica
  /// obligatoriamente recibir token. Luego la persona puede ingresar con los
  /// datos recién creados y obtener una sesión mock coherente.
  static String register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) {
    final normalizedEmail = email.trim().toLowerCase();

    if (_registeredUsersByEmail.containsKey(normalizedEmail)) {
      throw Exception('Ese email ya existe en la demo mock. Inicia sesión.');
    }

    final userId = _nextUserId++;
    _registeredUsersByEmail[normalizedEmail] = {
      'id': userId,
      'email': normalizedEmail,
      'nombrecompleto': fullName.trim(),
      'telefono': phone.trim(),
      'password': password,
    };

    _reservationsByClientId[userId] = [];

    return 'Registro mock exitoso. Ahora inicia sesión con $normalizedEmail y tu contraseña para continuar la demo.';
  }

  /// Búsqueda simple por ciudad.
  static List<PlaceModel> searchPlaces(SearchFilters filters) {
    final query = filters.city.trim().toLowerCase();
    final matches = _places.where((place) {
      final city = '${place['ciudad']}'.toLowerCase();
      final name = '${place['nombre']}'.toLowerCase();
      return city.contains(query) || name.contains(query);
    }).toList();

    return matches.map((item) => PlaceModel.fromJson(item)).toList();
  }

  /// Búsqueda avanzada mock: filtra lo suficiente para sostener la demo del
  /// flujo completo sin inventar lógica innecesaria.
  static List<PlaceModel> advancedSearch(SearchFilters filters) {
    return _places
        .where((place) {
          final cityMatches = '${place['ciudad']}'.toLowerCase().contains(
            filters.city.trim().toLowerCase(),
          );
          final guestsMatch = _asInt(place['cantPersonas']) >= filters.guests;
          final bedsMatch =
              filters.beds == 0 || _asInt(place['cantCamas']) >= filters.beds;
          final bathsMatch =
              filters.baths == 0 ||
              _asInt(place['cantBanios']) >= filters.baths;
          final roomsMatch =
              filters.rooms == 0 ||
              _asInt(place['cantHabitaciones']) >= filters.rooms;
          final parkingMatch =
              filters.parkingSpots == 0 ||
              _asInt(place['cantVehiculosParqueo']) >= filters.parkingSpots;
          final wifiMatch =
              filters.hasWifi == null ||
              _asBool(place['tieneWifi']) == filters.hasWifi;
          final priceMatch =
              filters.maxPricePerNight <= 0 ||
              _asDouble(place['precioNoche']) <= filters.maxPricePerNight;
          final descriptionMatch =
              filters.description.trim().isEmpty ||
              '${place['descripcion']}'.toLowerCase().contains(
                filters.description.trim().toLowerCase(),
              );

          return cityMatches &&
              guestsMatch &&
              bedsMatch &&
              bathsMatch &&
              roomsMatch &&
              parkingMatch &&
              wifiMatch &&
              priceMatch &&
              descriptionMatch;
        })
        .map((item) => PlaceModel.fromJson(item))
        .toList();
  }

  /// Detalle del lugar mock usando el mismo id que ve la UI en resultados.
  static PlaceModel getPlaceById(int id) {
    final match = _places.cast<Map<String, dynamic>?>().firstWhere(
      (place) => place?['id'] == id,
      orElse: () => null,
    );

    if (match == null) {
      throw Exception('No existe un lugar mock con id $id.');
    }

    return PlaceModel.fromJson(match);
  }

  /// Crea una reserva mock y la agrega al listado del cliente autenticado.
  static ReservationModel createReservation({
    required UserSession user,
    required PlaceModel place,
    required SearchFilters filters,
  }) {
    final quote = ReservationQuote.fromPlaceAndFilters(
      place: place,
      filters: filters,
    );

    final reservation = {
      'id': _nextReservationId++,
      'lugar_id': place.id,
      'nombreLugar': place.name,
      'nombreCliente': user.displayName,
      'fechaInicio': filters.checkInApi,
      'fechaFin': filters.checkOutApi,
      'cantidadNoches': quote.nights,
      'precioTotal': quote.total,
      'lugar': place.rawData,
      'cliente': {'id': user.id, 'nombrecompleto': user.displayName},
    };

    final clientReservations = _reservationsByClientId.putIfAbsent(
      user.id,
      () => [],
    );
    clientReservations.insert(0, reservation);

    return ReservationModel.fromJson(reservation);
  }

  /// Devuelve las reservas mock acumuladas del usuario actual.
  static List<ReservationModel> getClientReservations(UserSession user) {
    final reservations = _reservationsByClientId[user.id] ?? [];
    return reservations.map((item) => ReservationModel.fromJson(item)).toList();
  }

  /// Texto pedagógico para mostrar en la UI cuando se quiera aclarar la fuente
  /// de datos activa durante la demostración.
  static String get bannerMessage =>
      'Modo ${AppEnvironment.dataSourceLabel}: la app usa datos simulados para sostener la demo si el backend falla.';

  static int _asInt(Object? value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    final normalized = '$value'.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'si';
  }
}
