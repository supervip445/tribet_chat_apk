import '../api_service.dart';

class AdminViewService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getViews(String viewableType, int viewableId, {int limit = 100}) async {
    final response = await _apiService.get(
      '/admin/views',
      queryParameters: {
        'viewable_type': viewableType,
        'viewable_id': viewableId.toString(),
        'limit': limit.toString(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStats(String viewableType, int viewableId) async {
    final response = await _apiService.get(
      '/admin/views/stats',
      queryParameters: {
        'viewable_type': viewableType,
        'viewable_id': viewableId.toString(),
      },
    );
    return response.data;
  }
}

