import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'dart:developer' as developer;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'admin_token';
  static const String _userKey = 'admin_user';

  Future<Map<String, dynamic>> login(String userName, String password) async {
    try {
      final response = await _apiService.post(
        '/admin/login',
        data: {
          'user_name': userName,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = response.data['user'];

        // Store token and user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user));

        // Update API service with token
        _apiService.setAuthToken(token);

        return response.data;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      developer.log('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Call logout API if token exists
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token != null) {
        try {
          await _apiService.post('/admin/logout');
        } catch (e) {
          developer.log('Logout API error: $e');
        }
      }

      // Clear local storage
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      
      // Clear API service token
      _apiService.setAuthToken(null);
    } catch (e) {
      developer.log('Logout error: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('Get current user error: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> checkAdmin() async {
    try {
      final response = await _apiService.get('/admin/check');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Check admin error: $e');
      return false;
    }
  }

  Future<void> initializeAuth() async {
    final token = await getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }
}

