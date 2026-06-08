import 'package:flutter/material.dart';

import '../models/place_model.dart';
import '../models/search_filters.dart';
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

  List<PlaceModel> get results => _results;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SearchFilters? get lastFilters => _lastFilters;

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
}
