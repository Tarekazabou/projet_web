import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';

class RecipeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Recipe> _recipes = [];
  Recipe? _generatedRecipe;
  bool _isLoading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
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
      _generatedRecipe = Recipe.fromJson(data['recipe']);
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
      _generatedRecipe = Recipe.fromJson(data['recipe']);
      await loadRecipes();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
