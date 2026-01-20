import '../api_service.dart';

class AdminContactService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/contacts');
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/contacts/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('/admin/contacts/$id', data: data);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/contacts/$id');
  }

  Future<Map<String, dynamic>> markAsRead(int id) async {
    final response = await _apiService.post('/admin/contacts/$id/mark-as-read');
    return response.data;
  }
}

