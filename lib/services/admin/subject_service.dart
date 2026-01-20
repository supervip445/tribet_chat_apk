import '../api_service.dart';

class AdminSubjectService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/subjects');
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/subjects/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiService.post('/admin/subjects', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('/admin/subjects/$id', data: data);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/subjects/$id');
  }
}

