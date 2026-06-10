import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../models/reservation_model.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import '../services/reservations_service.dart';

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

  /// Reservas y feedback de creación son 100% dependientes de la sesión.
  /// Si el usuario cambia y dejamos este estado vivo, la UI puede mostrar una
  /// reserva ajena hasta que llegue otra carga. Preferimos reset inmediato.
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
    return _runRequest(() async {
      _reservations = await _reservationsService.getClientReservations(user);
    });
  }

  void clearFeedback() {
    _errorMessage = null;
    _lastCreatedReservation = null;
    notifyListeners();
  }

  Future<bool> _runRequest(Future<void> Function() executor) async {
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
    if (user == null || !user.hasToken) {
      return null;
    }

    return '${user.id}|${user.email}|${user.token}';
  }
}
