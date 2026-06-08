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

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReservationModel? get lastCreatedReservation => _lastCreatedReservation;

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
}
