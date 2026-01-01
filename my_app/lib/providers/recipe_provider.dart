import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Recipe> _recipes = [];
  List<Recipe> _suggestedRecipes = [];
  Recipe? _generatedRecipe;
  bool _isLoading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get suggestedRecipes => _suggestedRecipes;
  Recipe? get generatedRecipe => _generatedRecipe;
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
    notifyListeners();

    try {
      final params = {
        'ingredients': ingredients,
        'difficulty': difficulty,
        'servings': servings,
        'maxTime': maxTime,
        if (cuisine != null) 'cuisine': cuisine,
        if (dietaryPreferences != null && dietaryPreferences.isNotEmpty)
          'dietaryPreferences': dietaryPreferences,
      };

      final data = await _apiService.generateRecipe(params);
      // Check if data has nested structure with 'data' and 'recipe'
      if (data['data'] != null && data['data']['recipe'] != null) {
        _generatedRecipe = Recipe.fromJson(data['data']['recipe']);
      } else if (data['recipe'] != null) {
        _generatedRecipe = Recipe.fromJson(data['recipe']);
      } else {
        throw Exception('No recipe data found in response');
      }
      await loadRecipes(); // Refresh the list
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      final recipesData = data['recipes'] as List? ?? data['data']?['recipes'] as List? ?? [];
      _suggestedRecipes = recipesData.map((item) => Recipe.fromJson(item)).toList();
      
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
