import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userId != null) 'X-User-Id': userId,
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      AppLogger.apiRequest('GET', url);

      final headers = await _headers;
      final response = await _client
          .get(Uri.parse(url), headers: headers)
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

      final headers = await _headers;
      final response = await _client
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
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

      final headers = await _headers;
      final response = await _client
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
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

      final headers = await _headers;
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
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

  Future<Map<String, dynamic>> updateFridgeItem(
    String id,
    Map<String, dynamic> item,
  ) async {
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

  /// Generate multiple recipes (for recipe selection)
  Future<Map<String, dynamic>> generateMultipleRecipes(
    Map<String, dynamic> params,
  ) async {
    return await post('/recipes/generate-multiple', params);
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

  // ==================== Meal Plan Endpoints ====================

  Future<List<dynamic>> getMealPlans({
    String? startDate,
    String? endDate,
  }) async {
    String endpoint = '/meal-plans/';
    List<String> params = [];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final data = await get(endpoint);
    return data['meal_plans'] ?? [];
  }

  Future<Map<String, dynamic>> getWeekMealPlans({String? startDate}) async {
    String endpoint = '/meal-plans/week';
    if (startDate != null) endpoint += '?start_date=$startDate';
    return await get(endpoint);
  }

  Future<Map<String, dynamic>> createMealPlan(
    Map<String, dynamic> planData,
  ) async {
    return await post('/meal-plans/', planData);
  }

  Future<Map<String, dynamic>> updateMealPlan(
    String planId,
    Map<String, dynamic> planData,
  ) async {
    return await put('/meal-plans/$planId', planData);
  }

  Future<void> deleteMealPlan(String planId) async {
    await delete('/meal-plans/$planId');
  }

  Future<Map<String, dynamic>> getAIMealSuggestions({
    String? mealType,
    List<String>? preferences,
  }) async {
    return await post('/meal-plans/ai-suggest', {
      if (mealType != null) 'mealType': mealType,
      if (preferences != null) 'preferences': preferences,
    });
  }

  Future<Map<String, dynamic>> generateGroceryFromPlans(
    String startDate,
    String endDate,
  ) async {
    return await post('/meal-plans/generate-grocery', {
      'start_date': startDate,
      'end_date': endDate,
    });
  }

  // ==================== Grocery Endpoints ====================

  Future<Map<String, dynamic>> getGroceryItems() async {
    return await get('/grocery/items');
  }

  Future<Map<String, dynamic>> addGroceryItem(Map<String, dynamic> item) async {
    return await post('/grocery/items', item);
  }

  Future<Map<String, dynamic>> updateGroceryItem(
    int index,
    Map<String, dynamic> item,
  ) async {
    return await put('/grocery/items/$index', item);
  }

  Future<void> deleteGroceryItem(int index) async {
    await delete('/grocery/items/$index');
  }

  Future<Map<String, dynamic>> toggleGroceryItemPurchased(int index) async {
    return await post('/grocery/toggle-purchased/$index', {});
  }

  Future<Map<String, dynamic>> clearPurchasedItems() async {
    return await post('/grocery/clear-purchased', {});
  }

  Future<Map<String, dynamic>> createGroceryFromMealPlan(
    String startDate,
    String endDate,
  ) async {
    return await post('/grocery/from-meal-plan', {
      'start_date': startDate,
      'end_date': endDate,
    });
  }

  Future<Map<String, dynamic>> getGroceryStats() async {
    return await get('/grocery/stats');
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

  // ==================== Receipt Scanner Endpoints ====================

  /// Scan a receipt image and extract food items
  Future<Map<String, dynamic>> scanReceipt(String base64Image) async {
    return await post('/receipt/scan', {'image': base64Image});
  }

  /// Test if Ollama connection is available
  Future<Map<String, dynamic>> testReceiptScannerConnection() async {
    return await get('/receipt/test-connection');
  }

  // ==================== Food Scanner Endpoints ====================

  /// Scan a food image and get nutrition facts
  Future<Map<String, dynamic>> scanFood(
    String base64Image, {
    String? date,
    String? mealType,
    bool autoLog = false,
  }) async {
    return await post('/food/scan', {
      'image': base64Image,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      'auto_log': autoLog,
    });
  }

  /// Log a previously scanned food to nutrition tracker
  Future<Map<String, dynamic>> logScannedFood({
    required String mealName,
    required Map<String, dynamic> nutrition,
    List<String>? foodItems,
    String? date,
    String? mealType,
    String? portionSize,
    String? healthNotes,
  }) async {
    return await post('/food/log', {
      'meal_name': mealName,
      'nutrition': nutrition,
      if (foodItems != null) 'food_items': foodItems,
      if (date != null) 'date': date,
      if (mealType != null) 'meal_type': mealType,
      if (portionSize != null) 'portion_size': portionSize,
      if (healthNotes != null) 'health_notes': healthNotes,
    });
  }

  /// Get food scan history
  Future<Map<String, dynamic>> getFoodScanHistory({
    int limit = 10,
    String? date,
  }) async {
    String endpoint = '/food/history?limit=$limit';
    if (date != null) endpoint += '&date=$date';
    return await get(endpoint);
  }

  /// Dispose the client when done
  void dispose() {
    _client.close();
  }
}
