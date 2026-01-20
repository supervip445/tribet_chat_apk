import '../api_service.dart';

class AdminBiographyService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/biographies');
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/biographies/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(FormData formData) async {
    final response = await _apiService.post('/admin/biographies', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, FormData formData) async {
    final response = await _apiService.put('/admin/biographies/$id', data: formData);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/biographies/$id');
  }
}

