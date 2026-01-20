import '../api_service.dart';

class AdminBannerService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/banners');
    return response.data;
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _apiService.get('/admin/banners/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> create(FormData formData) async {
    final response = await _apiService.post('/admin/banners', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> update(int id, FormData formData) async {
    final response = await _apiService.put('/admin/banners/$id', data: formData);
    return response.data;
  }

  Future<void> delete(int id) async {
    await _apiService.delete('/admin/banners/$id');
  }
}

