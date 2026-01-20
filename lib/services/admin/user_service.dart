import '../api_service.dart';

class AdminUserService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAll() async {
    final response = await _apiService.get('/admin/users');
    return response.data;
  }
}

