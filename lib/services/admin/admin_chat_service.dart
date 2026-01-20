import 'dart:io';
import 'package:flutter/foundation.dart';
import '../api_service.dart';

class AdminChatService {
  final ApiService _apiService = ApiService();

  // Get all users assigned to the admin
  Future<dynamic> getUsers() async {
    try {
      final response = await _apiService.get('/admin/chat/users');
      debugPrint('Admin chat users API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getUsers: $e');
      rethrow;
    }
  }

  // Get messages for a specific user
  Future<dynamic> getMessages(int userId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await _apiService.get(
        '/admin/chat/users/$userId/messages',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );
      debugPrint('Admin chat messages API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getMessages: $e');
      rethrow;
    }
  }

  // Send message to a specific user
  Future<dynamic> sendMessage(int userId, {String? message, File? media}) async {
    try {
      dynamic data;
      if (media != null) {
        final formData = FormData();
        if (message != null && message.trim().isNotEmpty) {
          formData.append('message', message.trim());
        }
        formData.append('media', media);
        data = formData;
      } else {
        data = {
          'message': message ?? '',
        };
      }

      final response = await _apiService.post(
        '/admin/chat/users/$userId/messages',
        data: data,
      );
      debugPrint('Send admin message API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }
}

