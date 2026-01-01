import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/logger.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Network exception
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  final http.Client _client;
  String? _userId;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Set the current user ID for API requests
  void setUserId(String? userId) {
    _userId = userId;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add user ID to headers if available
    if (_userId != null && _userId!.isNotEmpty) {
      headers['X-User-Id'] = _userId!;
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      AppLogger.apiRequest('GET', url);

      final response = await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(AppConstants.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on http.ClientException {
      throw NetworkException('Connection failed');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      AppLogger.error('GET request failed', tag: 'API', error: e);
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      AppLogger.apiRequest('POST', url, body: body);

      final response = await _client
          .post(Uri.parse(url), headers: _headers, body: json.encode(body))
          .timeout(AppConstants.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url, body: response.body);

      // Return full response for auth endpoints
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on http.ClientException {
      throw NetworkException('Connection failed');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      AppLogger.error('POST request failed', tag: 'API', error: e);
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      AppLogger.apiRequest('PUT', url, body: body);

      final response = await _client
          .put(Uri.parse(url), headers: _headers, body: json.encode(body))
          .timeout(AppConstants.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on http.ClientException {
      throw NetworkException('Connection failed');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      AppLogger.error('PUT request failed', tag: 'API', error: e);
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      AppLogger.apiRequest('DELETE', url);

      final response = await _client
          .delete(Uri.parse(url), headers: _headers)
          .timeout(AppConstants.connectionTimeout);

      AppLogger.apiResponse(response.statusCode, url);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on http.ClientException {
      throw NetworkException('Connection failed');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      AppLogger.error('DELETE request failed', tag: 'API', error: e);
      throw ApiException('Request failed: ${e.toString()}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? json.decode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] ?? body;
    }

    final message = body['message'] ?? 'Request failed';

    switch (response.statusCode) {
      case 400:
        throw ApiException(
          'Bad request: $message',
          statusCode: 400,
          data: body,
        );
      case 401:
        throw ApiException(
          'Unauthorized: $message',
          statusCode: 401,
          data: body,
        );
      case 403:
        throw ApiException('Forbidden: $message', statusCode: 403, data: body);
      case 404:
        throw ApiException('Not found: $message', statusCode: 404, data: body);
      case 422:
        throw ApiException(
          'Validation error: $message',
          statusCode: 422,
          data: body,
        );
      case 500:
        throw ApiException(
          'Server error: $message',
          statusCode: 500,
          data: body,
        );
      default:
        throw ApiException(
          'Error: $message',
          statusCode: response.statusCode,
          data: body,
        );
    }
  }

  // ==================== Fridge Endpoints ====================

  Future<List<dynamic>> getFridgeItems() async {
    final data = await get('/fridge/items');
    return data['items'] ?? [];
  }

  Future<Map<String, dynamic>> addFridgeItem(Map<String, dynamic> item) async {
    return await post('/fridge/items', item);
  }

  Future<Map<String, dynamic>> updateFridgeItem(String id, Map<String, dynamic> item) async {
    return await put('/fridge/items/$id', item);
  }

  Future<void> deleteFridgeItem(String id) async {
    await delete('/fridge/items/$id');
  }

  Future<Map<String, dynamic>> suggestRecipesFromFridge() async {
    return await post('/fridge/suggest-recipes', {});
  }

  // ==================== Recipe Endpoints ====================

  Future<List<dynamic>> getRecipes({
    int perPage = AppConstants.defaultPageSize,
  }) async {
    final data = await get('/recipes/list?per_page=$perPage');
    return data['recipes'] ?? [];
  }

  Future<Map<String, dynamic>> getRecipeById(String id) async {
    final data = await get('/recipes/$id');
    return data['recipe'] ?? {};
  }

  Future<Map<String, dynamic>> generateRecipe(
    Map<String, dynamic> params,
  ) async {
    return await post('/recipes/generate-with-ai', params);
  }

  Future<Map<String, dynamic>> generateSimpleRecipe(
    Map<String, dynamic> params,
  ) async {
    return await post('/recipes/generate-simple', params);
  }

  // ==================== Nutrition Endpoints ====================

  Future<Map<String, dynamic>> getNutritionGoals() async {
    return await get('/nutrition/goals');
  }

  Future<Map<String, dynamic>> updateNutritionGoals(
    Map<String, dynamic> goals,
  ) async {
    return await post('/nutrition/goals', goals);
  }

  Future<Map<String, dynamic>> getDailyNutrition(String date) async {
    return await get('/nutrition/daily/$date');
  }

  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> mealData) async {
    return await post('/nutrition/log-meal', mealData);
  }

  Future<void> deleteMealLog(String mealId) async {
    await delete('/nutrition/meals/$mealId');
  }

  Future<Map<String, dynamic>> logWaterIntake(int amount, String date) async {
    return await post('/nutrition/water-intake', {
      'amount': amount,
      'date': date,
    });
  }

  Future<Map<String, dynamic>> getWeeklyTrend() async {
    return await get('/nutrition/weekly-trend');
  }

  // ==================== Dashboard Endpoints ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    return await get('/dashboard/stats');
  }

  Future<Map<String, dynamic>> getQuickActions() async {
    return await get('/dashboard/quick-actions');
  }

  Future<Map<String, dynamic>> getNutritionTips() async {
    return await get('/dashboard/nutrition-tips');
  }

  Future<Map<String, dynamic>> getRecentActivity() async {
    return await get('/dashboard/recent-activity');
  }

  // ==================== User Endpoints ====================

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    return await post('/users/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> registerUser(
    String email,
    String password,
    String username,
  ) async {
    return await post('/users/register', {
      'email': email,
      'password': password,
      'username': username,
    });
  }

  /// Dispose the client when done
  void dispose() {
    _client.close();
  }
}
