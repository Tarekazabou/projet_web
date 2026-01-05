import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Recipe> _recipes = [];
  List<Recipe> _suggestedRecipes = [];
  List<Recipe> _generatedRecipes = []; // Multiple generated recipes
  Recipe? _generatedRecipe;
  Recipe? _selectedRecipe; // User's selected recipe
  bool _isLoading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get suggestedRecipes => _suggestedRecipes;
  List<Recipe> get generatedRecipes => _generatedRecipes;
  Recipe? get generatedRecipe => _generatedRecipe;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getRecipes();
      _recipes = data.map((item) => Recipe.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateRecipe({
    required List<String> ingredients,
    String? cuisine,
    required String difficulty,
    required int servings,
    required int maxTime,
    List<String>? dietaryPreferences,
  }) async {
    _isLoading = true;
    _error = null;
    _generatedRecipe = null;
    _generatedRecipes = [];
    _selectedRecipe = null;
    notifyListeners();

    try {
      final params = {
        'ingredients': ingredients,
        'difficulty': difficulty,
        'servings': servings,
        'maxTime': maxTime,
        'count': 3, // Request 3 recipes
        if (cuisine != null) 'cuisine': cuisine,
        if (dietaryPreferences != null && dietaryPreferences.isNotEmpty)
          'dietaryPreferences': dietaryPreferences,
      };

      final data = await _apiService.generateMultipleRecipes(params);

      // DEBUG: Print response structure
      print('🔍 Response keys: ${data.keys}');
      print('🔍 Data type: ${data.runtimeType}');
      if (data['data'] != null) {
        print('🔍 data.keys: ${(data['data'] as Map).keys}');
      }
      if (data['recipes'] != null) {
        print('🔍 recipes length: ${(data['recipes'] as List).length}');
      }
      if (data['data'] != null && data['data']['recipes'] != null) {
        print('🔍 data.recipes length: ${(data['data']['recipes'] as List).length}');
      }

      // Parse multiple recipes
      if (data['recipes'] != null && data['recipes'] is List) {
        _generatedRecipes = (data['recipes'] as List)
            .map((item) => Recipe.fromJson(item))
            .toList();
        if (_generatedRecipes.isNotEmpty) {
          _generatedRecipe = _generatedRecipes.first;
        }
        print('✅ Parsed ${_generatedRecipes.length} recipes from data[recipes]');
      } else if (data['data'] != null && data['data']['recipes'] != null) {
        _generatedRecipes = (data['data']['recipes'] as List)
            .map((item) => Recipe.fromJson(item))
            .toList();
        if (_generatedRecipes.isNotEmpty) {
          _generatedRecipe = _generatedRecipes.first;
        }
        print('✅ Parsed ${_generatedRecipes.length} recipes from data[data][recipes]');
      } else if (data['data'] != null && data['data']['recipe'] != null) {
        // Fallback to single recipe
        _generatedRecipe = Recipe.fromJson(data['data']['recipe']);
        _generatedRecipes = [_generatedRecipe!];
        print('⚠️ Fallback: Got single recipe from data[data][recipe]');
      } else if (data['recipe'] != null) {
        _generatedRecipe = Recipe.fromJson(data['recipe']);
        _generatedRecipes = [_generatedRecipe!];
        print('⚠️ Fallback: Got single recipe from data[recipe]');
      } else {
        throw Exception('No recipe data found in response');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a recipe from generated recipes
  void selectRecipe(Recipe recipe) {
    _selectedRecipe = recipe;
    _generatedRecipe = recipe;
    notifyListeners();
  }

  /// Clear selected recipe
  void clearSelectedRecipe() {
    _selectedRecipe = null;
    notifyListeners();
  }

  /// Clear generated recipes
  void clearGeneratedRecipes() {
    _generatedRecipes = [];
    _generatedRecipe = null;
    _selectedRecipe = null;
    notifyListeners();
  }

  Future<void> suggestFromFridge() async {
    _isLoading = true;
    _error = null;
    _generatedRecipe = null;
    notifyListeners();

    try {
      final data = await _apiService.suggestRecipesFromFridge();
      if (data['data'] != null && data['data']['recipe'] != null) {
        _generatedRecipe = Recipe.fromJson(data['data']['recipe']);
        if (_generatedRecipe != null) {
          _recipes.insert(0, _generatedRecipe!);
        }
      } else {
        throw Exception('No recipe was generated.');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Suggest recipes based on given ingredients
  Future<void> suggestRecipes(List<String> ingredients) async {
    _isLoading = true;
    _error = null;
    _suggestedRecipes = [];
    notifyListeners();

    try {
      final data = await _apiService.post('/ai/suggest-recipes', {
        'ingredients': ingredients,
      });

      final recipesData =
          data['recipes'] as List? ?? data['data']?['recipes'] as List? ?? [];
      _suggestedRecipes = recipesData
          .map((item) => Recipe.fromJson(item))
          .toList();

      // If only one recipe returned, also set as generated recipe
      if (_suggestedRecipes.length == 1) {
        _generatedRecipe = _suggestedRecipes.first;
      }
    } catch (e) {
      _error = e.toString();
      // Don't rethrow - allow UI to handle empty suggestions gracefully
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear suggested recipes
  void clearSuggestedRecipes() {
    _suggestedRecipes = [];
    notifyListeners();
  }
}
