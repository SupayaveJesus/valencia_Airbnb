import '../config/app_environment.dart';
import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../models/reservation_quote.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import 'api_client.dart';
import 'mock/mock_cliente_data.dart';

class ReservationsService {
  ReservationsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ReservationModel> createReservation({
    required UserSession user,
    required PlaceModel place,
    required SearchFilters filters,
  }) async {
    if (AppEnvironment.useMockServices) {
      return MockClienteData.createReservation(
        user: user,
        place: place,
        filters: filters,
      );
    }

    final quote = ReservationQuote.fromPlaceAndFilters(
      place: place,
      filters: filters,
    );

    final response = await _apiClient.postResultToCandidates(
      paths: const ['/api/reservas', '/reservas'],
      token: user.token,
      body: {
        'lugar_id': place.id,
        'cliente_id': user.id,
        'fechaInicio': filters.checkInApi,
        'fechaFin': filters.checkOutApi,
        'precioTotal': quote.total.toStringAsFixed(2),
        'precioLimpieza': quote.cleaningFee.toStringAsFixed(2),
        'precioNoches': quote.nightsSubtotal.toStringAsFixed(2),
        'precioServicio': quote.serviceFee.toStringAsFixed(2),
      },
    );

    final data = _normalizeMap(response.response.data);
    return ReservationModel.fromJson(data, preferredBaseUrl: response.baseUrl);
  }

  Future<List<ReservationModel>> getClientReservations(UserSession user) async {
    if (AppEnvironment.useMockServices) {
      return MockClienteData.getClientReservations(user);
    }

    final response = await _apiClient.getResultToCandidates(
      paths: [
        '/api/reservas/cliente/${user.id}',
        '/reservas/cliente/${user.id}',
      ],
      token: user.token,
    );

    final reservations = _normalizeList(response.response.data);
    return reservations
        .map(
          (item) => ReservationModel.fromJson(
            item,
            preferredBaseUrl: response.baseUrl,
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _normalizeList(Object? rawData) {
    if (rawData is List) {
      return rawData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final map = _normalizeMap(rawData);
    const keys = ['data', 'reservas', 'items', 'results'];

    for (final key in keys) {
      final candidate = map[key];
      if (candidate is List) {
        return candidate
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }

    if (map.isNotEmpty) {
      return [map];
    }

    return [];
  }

  Map<String, dynamic> _normalizeMap(Object? rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }
}
