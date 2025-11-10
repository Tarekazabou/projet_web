import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      final userName = prefs.getString('user_name');

      if (userId != null && userEmail != null) {
        _currentUser = User(
          id: userId,
          email: userEmail,
          name: userName ?? 'User',
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      _error = e.toString();
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
      print('🔐 Attempting login for: $email');
      final response = await _apiService.post('/users/login', {
        'email': email,
        'password': password,
      });

      print('📥 Login response: $response');

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data'];
        _currentUser = User(
          id: userData['user_id'] ?? userData['id'] ?? 'demo_user_01',
          email: userData['email'] ?? email,
          name: userData['username'] ?? userData['name'] ?? 'User',
        );

        print('✅ Login successful for user: ${_currentUser!.name}');

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_name', _currentUser!.name);

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        print('❌ Login failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      print('❌ Login error: $_error');
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
      final response = await _apiService.post('/users/register', {
        'email': email,
        'password': password,
        'username': username,
      });

      if (response['success'] == true) {
        // After successful signup, automatically login
        final loginSuccess = await login(email, password);
        return loginSuccess;
      } else {
        _error = response['message'] ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
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
