import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _authService.initializeAuth();
    final isAuth = await _authService.isAuthenticated();
    
    if (isAuth) {
      _user = await _authService.getCurrentUser();
      _isAuthenticated = true;
      
      // Verify token is still valid
      try {
        final isValid = await _authService.checkAdmin();
        if (!isValid) {
          await logout();
        }
      } catch (e) {
        developer.log('Auth check error: $e');
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String userName, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.login(userName, password);
      _user = response['user'];
      _isAuthenticated = true;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

