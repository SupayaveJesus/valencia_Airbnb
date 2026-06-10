import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../models/search_filters.dart';
import '../models/user_session.dart';
import '../services/places_service.dart';

class PlacesProvider extends ChangeNotifier {
  PlacesProvider({PlacesService? placesService})
    : _placesService = placesService ?? PlacesService();

  final PlacesService _placesService;

  /// Flujo pedagógico: UI -> provider -> service -> API -> model -> UI.
  List<PlaceModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  SearchFilters? _lastFilters;
  String? _sessionFingerprint;

  List<PlaceModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SearchFilters? get lastFilters => _lastFilters;

  /// Aunque el provider vive a nivel app, su contenido NO es global de negocio:
  /// los resultados dependen de quién está autenticado. Si cambia la sesión,
  /// vaciamos este cache visual para que la demo no mezcle usuarios.
  void syncSession(UserSession? user) {
    final nextFingerprint = _buildSessionFingerprint(user);
    if (_sessionFingerprint == nextFingerprint) {
      return;
    }

    _sessionFingerprint = nextFingerprint;
    _results = [];
    _lastFilters = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> searchSimple(SearchFilters filters) async {
    return _runSearch(() => _placesService.searchPlaces(filters), filters);
  }

  Future<bool> searchAdvanced(SearchFilters filters) async {
    return _runSearch(() => _placesService.advancedSearch(filters), filters);
  }

  Future<PlaceModel> loadPlaceDetail(int placeId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      return await _placesService.getPlaceById(placeId);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runSearch(
    Future<List<PlaceModel>> Function() executor,
    SearchFilters filters,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _lastFilters = filters;
    notifyListeners();

    try {
      _results = await executor();
      return true;
    } catch (error) {
      _results = [];
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
