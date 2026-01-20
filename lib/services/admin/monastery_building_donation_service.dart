import '../api_service.dart';

class AdminMonasteryBuildingDonationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/monastery-building-donations');
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/monastery-building-donations/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _apiService.post('/admin/monastery-building-donations', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _apiService.put('/admin/monastery-building-donations/$id', data: data);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/monastery-building-donations/$id');
  }
}

