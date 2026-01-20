import '../api_service.dart';

class AdminDonationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll(int? page) async {
    final response = await _apiService.get('/admin/donations',
    queryParameters: {
      "page": page
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/donations/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiService.post('/admin/donations', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('/admin/donations/$id', data: data);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/donations/$id');
  }

  Future<Map<String, dynamic>> approve(int id) async {
    final response = await _apiService.post('/admin/donations/$id/approve');
    return response.data;
  }

  Future<Map<String, dynamic>> reject(int id) async {
    final response = await _apiService.post('/admin/donations/$id/reject');
    return response.data;
  }
}

