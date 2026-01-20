import '../api_service.dart';

class AdminPostService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll(int? page) async {
    final response = await _apiService.get('/admin/posts',
      queryParameters: {
        "page": page
      }
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/posts/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(FormData formData) async {
    final response = await _apiService.post('/admin/posts', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, FormData formData) async {
    final response = await _apiService.put('/admin/posts/$id', data: formData);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/posts/$id');
  }
}

