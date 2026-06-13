import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../models/reservation_quote.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import 'api_client.dart';

/// Capa que traduce el flujo de reservas entre modelos de UI y HTTP real.
///
/// Responsabilidad:
/// - construir payloads con el contrato que espera la API,
/// - absorber diferencias de envoltorios en las respuestas,
/// - devolver modelos ya normalizados para que provider y pantallas trabajen
///   con un contrato único.
class ReservationsService {
  ReservationsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ReservationModel> createReservation({
    required UserSession user,
    required PlaceModel place,
    required SearchFilters filters,
  }) async {
    // Primero se calcula la cotización local. Eso permite que la misma lógica
    // alimente dos cosas: el resumen visible en la confirmación y el payload que
    // la API persiste como reserva confirmada.
    final quote = ReservationQuote.fromPlaceAndFilters(
      place: place,
      filters: filters,
    );

    final response = await _apiClient.postResultToCandidates(
      paths: const ['/api/reservas', '/reservas'],
      // El flujo real de reservas se identifica por `cliente_id`. Si la sesión
      // trae token lo reenviamos, pero la creación NO depende de él para
      // funcionar hoy; el dato imprescindible para la API es el cliente activo.
      token: user.hasToken ? user.token : null,
      body: {
        // El backend recibe ids, fechas ISO y precios desglosados. Dejarlos
        // explícitos acá ayuda a defender qué viaja por red en este caso de uso.
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

    // La confirmación debe sobrevivir a ambas respuestas reales del backend:
    // reserva plana o reserva encapsulada en `data` / `reserva`.
    final data = _unwrapMap(
      response.response.data,
      candidateKeys: const ['data', 'reserva'],
    );
    return ReservationModel.fromJson(data, preferredBaseUrl: response.baseUrl);
  }

  Future<List<ReservationModel>> getClientReservations(UserSession user) async {
    // El historial está acotado al cliente logueado. La pantalla nunca consulta
    // "todas" las reservas: siempre consume `/reservas/cliente/{id}`.
    final response = await _apiClient.getResultToCandidates(
      paths: [
        '/api/reservas/cliente/${user.id}',
        '/reservas/cliente/${user.id}',
      ],
      token: user.hasToken ? user.token : null,
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
    // El listado real a veces llega como array directo y otras veces dentro de
    // contenedores (`data`, `reservas`, etc.). La pantalla de historial no
    // debería conocer esas variantes de transporte.
    if (rawData is List) {
      return rawData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final map = _normalizeMap(rawData);
    const keys = ['data', 'reservas', 'items', 'results', 'value'];

    for (final key in keys) {
      final candidate = map[key];
      if (candidate is List) {
        return candidate
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }

    if (map.isNotEmpty) {
      // Fallback útil cuando el backend devuelve un único objeto en vez de una
      // colección: la UI igual puede renderizarlo como lista de un elemento.
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

  Map<String, dynamic> _unwrapMap(
    Object? rawData, {
    List<String> candidateKeys = const [],
  }) {
    // La confirmación usa esta rutina para ignorar wrappers de transporte y
    // quedarse con la reserva útil. Así el provider no depende del shape exacto
    // de la respuesta HTTP, solo del resultado de negocio.
    final map = _normalizeMap(rawData);

    for (final key in candidateKeys) {
      final candidate = map[key];
      final unwrapped = _normalizeMap(candidate);
      if (unwrapped.isNotEmpty) {
        return unwrapped;
      }
    }

    return map;
  }
}
