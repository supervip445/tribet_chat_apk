import '../api_service.dart';

class AdminLessonService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll(int? page) async {
    final response = await _apiService.get('/admin/lessons',
    queryParameters: {
      "page": page
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/lessons/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(FormData formData) async {
    final response = await _apiService.post('/admin/lessons', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, FormData formData) async {
    final response = await _apiService.put('/admin/lessons/$id', data: formData);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/lessons/$id');
  }
}

