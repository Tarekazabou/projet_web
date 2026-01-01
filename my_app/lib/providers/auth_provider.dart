import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      final userEmail = prefs.getString(AppConstants.userEmailKey);
      final userName = prefs.getString(AppConstants.userNameKey);

      if (userId != null && userEmail != null) {
        _currentUser = User(
          id: userId,
          email: userEmail,
          name: userName ?? 'User',
        );
        _isAuthenticated = true;
        
        // Set user ID in API service for subsequent requests
        _apiService.setUserId(userId);
        
        AppLogger.info(
          'User session restored: ${_currentUser!.email}',
          tag: 'Auth',
        );
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to initialize auth', tag: 'Auth', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('Attempting login for: $email', tag: 'Auth');
      final response = await _apiService.post('/users/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];
        _currentUser = User(
          id: userData['user_id'] ?? userData['id'] ?? 'demo_user_01',
          email: userData['email'] ?? email,
          name: userData['username'] ?? userData['name'] ?? 'User',
        );

        AppLogger.success(
          'Login successful for user: ${_currentUser!.name}',
          tag: 'Auth',
        );

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, _currentUser!.id);
        await prefs.setString(AppConstants.userEmailKey, _currentUser!.email);
        await prefs.setString(AppConstants.userNameKey, _currentUser!.name);

        // Set user ID in API service for subsequent requests
        _apiService.setUserId(_currentUser!.id);

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        AppLogger.warning('Login failed: $_error', tag: 'Auth');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      AppLogger.error('Login error', tag: 'Auth', error: e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Signup
  Future<bool> signup(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('Attempting signup for: $email', tag: 'Auth');
      final response = await _apiService.post('/users/register', {
        'email': email,
        'password': password,
        'username': username,
      });

      if (response['success'] == true) {
        AppLogger.success(
          'Signup successful, proceeding to login',
          tag: 'Auth',
        );
        // After successful signup, automatically login
        final loginSuccess = await login(email, password);
        return loginSuccess;
      } else {
        _error = response['message'] ?? 'Signup failed';
        AppLogger.warning('Signup failed: $_error', tag: 'Auth');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      AppLogger.error('Signup error', tag: 'Auth', error: e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userEmailKey);
      await prefs.remove(AppConstants.userNameKey);

      // Clear user ID from API service
      _apiService.setUserId(null);

      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
      AppLogger.info('User logged out', tag: 'Auth');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Logout error', tag: 'Auth', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
