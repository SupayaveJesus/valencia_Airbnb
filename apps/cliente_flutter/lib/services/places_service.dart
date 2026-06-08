import '../models/place_model.dart';
import '../models/search_filters.dart';
import 'api_client.dart';

class PlacesService {
  PlacesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PlaceModel>> searchPlaces(SearchFilters filters) async {
    final response = await _apiClient.postResultToCandidates(
      paths: const ['/api/lugares/search', '/lugares/search'],
      body: filters.toSimplePayload(),
    );

    final places = _normalizeList(response.response.data);
    return places
        .map((item) => PlaceModel.fromJson(item, preferredBaseUrl: response.baseUrl))
        .toList();
  }

  Future<List<PlaceModel>> advancedSearch(SearchFilters filters) async {
    final response = await _apiClient.postResultToCandidates(
      paths: const ['/api/lugares/advancedsearch', '/lugares/advancedsearch'],
      body: filters.toAdvancedPayload(),
    );

    final places = _normalizeList(response.response.data);
    return places
        .map((item) => PlaceModel.fromJson(item, preferredBaseUrl: response.baseUrl))
        .toList();
  }

  Future<PlaceModel> getPlaceById(int id) async {
    final response = await _apiClient.getResultToCandidates(
      paths: ['/api/lugares/$id', '/lugares/$id'],
    );

    final data = _normalizeMap(response.response.data);
    return PlaceModel.fromJson(data, preferredBaseUrl: response.baseUrl);
  }

  List<Map<String, dynamic>> _normalizeList(Object? rawData) {
    if (rawData is List) {
      return rawData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final map = _normalizeMap(rawData);
    const candidateKeys = ['data', 'lugares', 'results', 'items'];

    for (final key in candidateKeys) {
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
