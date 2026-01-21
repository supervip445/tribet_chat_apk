import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'dart:developer' as developer;

class PublicAuthService {
  static final PublicAuthService _instance = PublicAuthService._internal();
  factory PublicAuthService() => _instance;
  PublicAuthService._internal();

  final ApiService _apiService = ApiService();
  static const String _tokenKey = 'public_token';
  static const String _userKey = 'public_user';

  Future<Map<String, dynamic>> register({
    required String name,
    required int age,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        '/public/register',
        data: {
          'name': name,
          'age': age,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 201 && response.data['token'] != null) {
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
        throw Exception('Registration failed');
      }
    } catch (e) {
      developer.log('Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String userName, String password) async {
    try {
      debugPrint("username: $userName, password: $password");

      final response = await _apiService.post(
        '/public/login',
        data: {
          'user_name': userName,
          'password': password,
        },
      );
      
      debugPrint("Login response: $response");
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
      }

      throw Exception(_extractMessage(response.data) ?? 'Login failed');
    } catch (e) {
      debugPrint("Login error: $e");
      final message = _extractDioMessage(e) ?? 'Login failed';
      developer.log('Login error: $message');
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    try {
      // Call logout API if token exists
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null) {
        try {
          await _apiService.post('/public/logout');
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

  Future<void> initializeAuth() async {
    final token = await getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty && value.first is String) {
            return value.first as String;
          }
        }
      }
    }
    return null;
  }

  String? _extractDioMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      return _extractMessage(responseData) ?? error.message;
    }
    return null;
  }
}
