import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  // Get messages for the current user
  Future<dynamic> getMessages({int page = 1, int perPage = 20}) async {
    try {
      final response = await _apiService.get(
        '/public/chat/messages',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      debugPrint('Chat messages API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getMessages: $e');
      rethrow;
    }
  }

  // Send a message
  Future<dynamic> sendMessage({String? message, File? media}) async {
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
        data = {'message': message ?? ''};
      }
      final response = await _apiService.post(
        '/public/chat/messages',
        data: data,
      );
      debugPrint('Send message API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }
}
