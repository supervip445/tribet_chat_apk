import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PublicService {
  final ApiService _apiService = ApiService();

  // Posts
  Future<dynamic> getPosts(int? page) async {
    try {
      final response = await _apiService.get(ApiConfig.publicPosts,
      queryParameters: {
        "page": page
      });
      debugPrint('Posts API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getPosts: $e');
      rethrow;
    }
  }

  Future<dynamic> getPost(int id) async {
    final response = await _apiService.get('${ApiConfig.publicPosts}/$id');
    return response.data;
  }

  // Dhamma Talks
  Future<dynamic> getDhammas(int? page) async {
    try {
      final response = await _apiService.get(ApiConfig.publicDhammas,
      queryParameters: {
        "page": page
      });
      debugPrint('Dhammas API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getDhammas: $e');
      rethrow;
    }
  }

  Future<dynamic> getDhamma(int id) async {
    final response = await _apiService.get('${ApiConfig.publicDhammas}/$id');
    return response.data;
  }

  // Biographies
  Future<dynamic> getBiographies() async {
    final response = await _apiService.get(ApiConfig.publicBiographies);
    return response.data;
  }

  Future<dynamic> getBiography(int id) async {
    final response = await _apiService.get('${ApiConfig.publicBiographies}/$id');
    return response.data;
  }

  // Donations
  Future<dynamic> getDonations(int? page) async {
    try {
      debugPrint('🔍 PublicService: Fetching donations from ${ApiConfig.publicDonations}');
      final response = await _apiService.get(ApiConfig.publicDonations,
        queryParameters: {
          "page": page
        }
      );
      debugPrint('📦 PublicService: Donations response status: ${response.statusCode}');
      debugPrint('📦 PublicService: Donations response data: ${response.data}');
      debugPrint('📦 PublicService: Donations response data type: ${response.data.runtimeType}');
      return response.data;
    } catch (e) {
      debugPrint('❌ PublicService: Error in getDonations: $e');
      rethrow;
    }
  }

  // Monasteries
  Future<dynamic> getMonasteries() async {
    final response = await _apiService.get(ApiConfig.publicMonasteries);
    return response.data;
  }

  // Monastery Building Donations
  Future<dynamic> getMonasteryBuildingDonations() async {
    final response = await _apiService.get('/public/monastery-building-donations');
    return response.data;
  }

  // Lessons
  Future<dynamic> getLessons(int? page) async {
    try {
      final response = await _apiService.get(ApiConfig.publicLessons,
      queryParameters: {
        "page": page
      });
      debugPrint('Lessons API Response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('Error in getLessons: $e');
      rethrow;
    }
  }

  Future<dynamic> getLesson(int id) async {
    final response = await _apiService.get('${ApiConfig.publicLessons}/$id');
    return response.data;
  }

  // Banners
  Future<dynamic> getBanners() async {
    final response = await _apiService.get(ApiConfig.publicBanners);
    return response.data;
  }

  Future<dynamic> getBannerTexts() async {
    final response = await _apiService.get(ApiConfig.publicBannerTexts);
    return response.data;
  }

  // Likes/Dislikes
  Future<dynamic> toggleLike(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConfig.publicLikesToggle, data: data);
    return response.data;
  }

  Future<dynamic> getLikeCounts(Map<String, dynamic> params) async {
    final response = await _apiService.get(ApiConfig.publicLikesCounts, queryParameters: params);
    return response.data;
  }

  // Comments
  Future<dynamic> getComments(Map<String, dynamic> params) async {
    final response = await _apiService.get(ApiConfig.publicComments, queryParameters: params);
    return response.data;
  }

  Future<dynamic> addComment(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConfig.publicComments, data: data);
    return response.data;
  }
}

