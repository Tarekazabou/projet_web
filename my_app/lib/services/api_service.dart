import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:5000/api';
  
  // For Android Emulator use: http://10.0.2.2:5000/api
  // For iOS Simulator use: http://localhost:5000/api
  // For real device use your computer's IP: http://192.168.1.x:5000/api

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '$baseUrl$endpoint';
      print('📤 POST Request to: $url');
      print('📤 Request body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      // Return full response for auth endpoints
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // Fridge endpoints
  Future<List<dynamic>> getFridgeItems() async {
    final data = await get('/fridge/items');
    return data['items'] ?? [];
  }

  Future<Map<String, dynamic>> addFridgeItem(Map<String, dynamic> item) async {
    return await post('/fridge/items', item);
  }

  Future<void> deleteFridgeItem(String id) async {
    await delete('/fridge/items/$id');
  }

  Future<Map<String, dynamic>> suggestRecipesFromFridge() async {
    return await post('/fridge/suggest-recipes', {});
  }

  // Recipe endpoints
  Future<List<dynamic>> getRecipes({int perPage = 20}) async {
    final data = await get('/recipes/list?per_page=$perPage');
    return data['recipes'] ?? [];
  }

  Future<Map<String, dynamic>> getRecipeById(String id) async {
    final data = await get('/recipes/$id');
    return data['recipe'] ?? {};
  }

  Future<Map<String, dynamic>> generateRecipe(Map<String, dynamic> params) async {
    return await post('/recipes/generate-with-ai', params);
  }

  Future<Map<String, dynamic>> generateSimpleRecipe(Map<String, dynamic> params) async {
    return await post('/recipes/generate-simple', params);
  }
}
