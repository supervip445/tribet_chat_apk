import 'package:dio/dio.dart' as package;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Helper class to create FormData for multipart requests
class FormData {
  final Map<String, dynamic> fields = {};
  final Map<String, List<File>> files = {};

  void append(String key, dynamic value) {
    if (value is File) {
      if (!files.containsKey(key)) {
        files[key] = [];
      }
      files[key]!.add(value);
    } else {
      fields[key] = value;
    }
  }

  void appendList(String key, List<File> fileList) {
    files[key] = fileList;
  }
}

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = package.Dio(
      package.BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors for error handling and auth
    _dio.interceptors.add(
      package.InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Load token from SharedPreferences if not already set
          if (_authToken == null) {
            await _loadTokenFromStorage();
          }
          
          // Determine which token to use based on route
          final prefs = await SharedPreferences.getInstance();
          String? tokenToUse = _authToken;
          
          // For admin routes, use admin token
          if (options.path.contains('/admin/') && !options.path.contains('/admin/login')) {
            tokenToUse = prefs.getString('admin_token');
          }
          // For public protected routes, use public token
          else if (options.path.contains('/public/profile') || 
                   options.path.contains('/public/logout') ||
                   options.path.contains('/public/chat/')) {
            tokenToUse = prefs.getString('public_token');
          }
          // For other routes, try both (admin first, then public)
          tokenToUse = prefs.getString('admin_token') ?? prefs.getString('public_token');

          
          // Add auth token to headers if available
          if (tokenToUse != null) {
            options.headers['Authorization'] = 'Bearer $tokenToUse';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Error logging - can be removed in production
          return handler.next(error);
        },
      ),
    );
  }

  late package.Dio _dio;
  String? _authToken;

  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try admin token first, then public token
      var token = prefs.getString('admin_token');
      if (token == null || token.isEmpty) {
        token = prefs.getString('public_token');
      }
      if (token != null && token.isNotEmpty) {
        _authToken = token;
      }
    } catch (e) {
      // Ignore errors when loading token
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // GET request
  Future<package.Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<package.Response> post(String path, {dynamic data}) async {
    try {
      if (data is FormData) {
        // Handle multipart/form-data
        final dioFormData = await _createDioFormData(data);
        return await _dio.post(
          path,
          data: dioFormData,
          options: package.Options(
            contentType: 'multipart/form-data',
          ),
        );
      }
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<package.Response> put(String path, {dynamic data}) async {
    try {
      if (data is FormData) {
        // Handle multipart/form-data
        final dioFormData = await _createDioFormData(data);
        return await _dio.put(
          path,
          data: dioFormData,
          options: package.Options(
            contentType: 'multipart/form-data',
          ),
        );
      }
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<package.FormData> _createDioFormData(FormData formData) async {
    final dioFormData = package.FormData.fromMap(formData.fields);
    
    // Add files
    for (var entry in formData.files.entries) {
      for (var file in entry.value) {
        final fileName = file.path.split('/').last;
        dioFormData.files.add(
          MapEntry(
            entry.key,
            await package.MultipartFile.fromFile(
              file.path,
              filename: fileName,
            ),
          ),
        );
      }
    }
    
    return dioFormData;
  }

  // DELETE request
  Future<package.Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}

