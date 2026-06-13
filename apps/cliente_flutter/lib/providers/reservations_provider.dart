import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import '../services/reservations_service.dart';

/// Estado de aplicación del bloque de reservas.
///
/// Qué vive acá:
/// - listado de reservas del cliente activo,
/// - loading/error de requests,
/// - última reserva creada para refrescar feedback entre pantallas.
///
/// Qué NO vive acá: detalles visuales de cada screen. El provider concentra el
/// estado compartido para que confirmación e historial reaccionen al mismo dato.
class ReservationsProvider extends ChangeNotifier {
  ReservationsProvider({ReservationsService? reservationsService})
    : _reservationsService = reservationsService ?? ReservationsService();

  final ReservationsService _reservationsService;

  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  ReservationModel? _lastCreatedReservation;
  String? _sessionFingerprint;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReservationModel? get lastCreatedReservation => _lastCreatedReservation;

  /// Reservas y feedback de creación son 100% dependientes del cliente activo.
  /// Si el usuario cambia y dejamos este estado vivo, la UI puede mostrar una
  /// reserva ajena hasta que llegue otra carga. Por eso la huella se arma con
  /// identidad estable (`id + email`) y no con estados visuales transitorios.
  void syncSession(UserSession? user) {
    final nextFingerprint = _buildSessionFingerprint(user);
    if (_sessionFingerprint == nextFingerprint) {
      return;
    }

    _sessionFingerprint = nextFingerprint;
    _reservations = [];
    _lastCreatedReservation = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReservation({
    required UserSession user,
    required PlaceModel place,
    required SearchFilters filters,
  }) async {
    // Si la creación sale bien, insertamos la reserva al principio de la lista.
    // Consecuencia UX: al navegar a "Mis reservas", la nueva reserva aparece
    // inmediatamente arriba sin esperar una recarga manual extra.
    return _runRequest(() async {
      _lastCreatedReservation = await _reservationsService.createReservation(
        user: user,
        place: place,
        filters: filters,
      );

      if (_lastCreatedReservation != null) {
        _reservations = [_lastCreatedReservation!, ..._reservations];
      }
    });
  }

  Future<bool> loadClientReservations(UserSession user) async {
    // El historial se reemplaza completo porque representa la foto actual del
    // backend para ese cliente, no una paginación incremental.
    return _runRequest(() async {
      _reservations = await _reservationsService.getClientReservations(user);
    });
  }

  void clearFeedback() {
    // Limpia errores o resultados previos antes de iniciar un nuevo intento.
    _errorMessage = null;
    _lastCreatedReservation = null;
    notifyListeners();
  }

  Future<bool> _runRequest(Future<void> Function() executor) async {
    // Contrato común para las pantallas: `true` si la operación terminó bien,
    // `false` si hubo error. Además centraliza loading + mensaje visible.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await executor();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _buildSessionFingerprint(UserSession? user) {
    if (user == null || !user.hasIdentity) {
      return null;
    }

    return '${user.id}|${user.email}';
  }
}
