import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Model for nutrition goals
class NutritionGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int water;

  NutritionGoals({
    this.calories = 2000,
    this.protein = 100,
    this.carbs = 250,
    this.fat = 65,
    this.fiber = 25,
    this.water = 8,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      calories: json['calories'] ?? 2000,
      protein: json['protein'] ?? 100,
      carbs: json['carbs'] ?? 250,
      fat: json['fat'] ?? 65,
      fiber: json['fiber'] ?? 25,
      water: json['water'] ?? 8,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'water': water,
  };
}

/// Model for daily nutrition summary
class DailyNutrition {
  final int caloriesConsumed;
  final int caloriesGoal;
  final int proteinConsumed;
  final int proteinGoal;
  final int carbsConsumed;
  final int carbsGoal;
  final int fatConsumed;
  final int fatGoal;
  final int waterConsumed;
  final int waterGoal;

  DailyNutrition({
    this.caloriesConsumed = 0,
    this.caloriesGoal = 2000,
    this.proteinConsumed = 0,
    this.proteinGoal = 100,
    this.carbsConsumed = 0,
    this.carbsGoal = 250,
    this.fatConsumed = 0,
    this.fatGoal = 65,
    this.waterConsumed = 0,
    this.waterGoal = 8,
  });

  double get caloriesPercentage => caloriesGoal > 0
      ? (caloriesConsumed / caloriesGoal * 100).clamp(0, 100)
      : 0;
  double get proteinPercentage =>
      proteinGoal > 0 ? (proteinConsumed / proteinGoal * 100).clamp(0, 100) : 0;
  double get carbsPercentage =>
      carbsGoal > 0 ? (carbsConsumed / carbsGoal * 100).clamp(0, 100) : 0;
  double get fatPercentage =>
      fatGoal > 0 ? (fatConsumed / fatGoal * 100).clamp(0, 100) : 0;
  double get waterPercentage =>
      waterGoal > 0 ? (waterConsumed / waterGoal * 100).clamp(0, 100) : 0;

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    final totals = json['total_nutrition'] ?? json['totals'] ?? {};
    final goals = json['goals'] ?? {};

    return DailyNutrition(
      caloriesConsumed: totals['calories'] ?? 0,
      caloriesGoal: goals['calories'] ?? 2000,
      proteinConsumed: totals['protein'] ?? 0,
      proteinGoal: goals['protein'] ?? 100,
      carbsConsumed: totals['carbs'] ?? 0,
      carbsGoal: goals['carbs'] ?? 250,
      fatConsumed: totals['fat'] ?? 0,
      fatGoal: goals['fat'] ?? 65,
      waterConsumed: json['water_intake'] ?? 0,
      waterGoal: goals['water'] ?? 8,
    );
  }
}

/// Model for a logged meal
class MealLog {
  final String id;
  final String mealName;
  final String mealType;
  final String date;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime? createdAt;

  MealLog({
    required this.id,
    required this.mealName,
    required this.mealType,
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.createdAt,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] ?? {};
    return MealLog(
      id: json['id'] ?? '',
      mealName: json['mealName'] ?? json['meal_name'] ?? 'Unknown',
      mealType: json['mealType'] ?? json['meal_type'] ?? 'other',
      date: json['date'] ?? '',
      calories: nutrition['calories'] ?? 0,
      protein: nutrition['protein'] ?? 0,
      carbs: nutrition['carbs'] ?? 0,
      fat: nutrition['fat'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get mealTypeDisplay {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Snack';
      default:
        return mealType;
    }
  }
}

/// Provider for nutrition data
class NutritionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  NutritionGoals _goals = NutritionGoals();
  DailyNutrition _dailyNutrition = DailyNutrition();
  List<MealLog> _todaysMeals = [];
  List<Map<String, dynamic>> _weeklyTrend = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  NutritionGoals get goals => _goals;
  DailyNutrition get dailyNutrition => _dailyNutrition;
  List<MealLog> get todaysMeals => _todaysMeals;
  List<Map<String, dynamic>> get weeklyTrend => _weeklyTrend;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties for easy access
  int get caloriesConsumed => _dailyNutrition.caloriesConsumed;
  int get caloriesGoal => _dailyNutrition.caloriesGoal;
  double get caloriesProgress => _dailyNutrition.caloriesPercentage / 100;

  int get proteinConsumed => _dailyNutrition.proteinConsumed;
  int get proteinGoal => _dailyNutrition.proteinGoal;

  int get carbsConsumed => _dailyNutrition.carbsConsumed;
  int get carbsGoal => _dailyNutrition.carbsGoal;

  int get fatConsumed => _dailyNutrition.fatConsumed;
  int get fatGoal => _dailyNutrition.fatGoal;

  // Water tracking
  int get waterGlasses => _dailyNutrition.waterConsumed;
  int get waterGoal => _dailyNutrition.waterGoal;

  // Nutrition tips (placeholder)
  List<String> get nutritionTips => [
    'Drink at least 8 glasses of water daily',
    'Include protein in every meal for sustained energy',
    'Eat a variety of colorful vegetables',
    'Limit processed foods and added sugars',
  ];

  /// Load all nutrition data
  Future<void> loadNutritionData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([loadGoals(), loadDailyNutrition(), loadWeeklyTrend()]);
    } catch (e) {
      _error = e.toString();
      AppLogger.error(
        'Failed to load nutrition data',
        tag: 'Nutrition',
        error: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load nutrition goals
  Future<void> loadGoals() async {
    try {
      final response = await _apiService.get('/nutrition/goals');
      if (response['goals'] != null) {
        _goals = NutritionGoals.fromJson(response['goals']);
      }
    } catch (e) {
      AppLogger.error('Failed to load goals', tag: 'Nutrition', error: e);
    }
  }

  /// Load daily nutrition data
  Future<void> loadDailyNutrition([String? date]) async {
    try {
      final dateStr = date ?? _formatDate(DateTime.now());
      final response = await _apiService.get('/nutrition/daily/$dateStr');

      _dailyNutrition = DailyNutrition.fromJson(response);

      final meals = response['meals'] as List? ?? [];
      _todaysMeals = meals.map((m) => MealLog.fromJson(m)).toList();
    } catch (e) {
      AppLogger.error(
        'Failed to load daily nutrition',
        tag: 'Nutrition',
        error: e,
      );
    }
  }

  /// Load weekly trend data
  Future<void> loadWeeklyTrend() async {
    try {
      final response = await _apiService.get('/nutrition/weekly-trend');
      _weeklyTrend = List<Map<String, dynamic>>.from(response['trend'] ?? []);
    } catch (e) {
      AppLogger.error(
        'Failed to load weekly trend',
        tag: 'Nutrition',
        error: e,
      );
      // Default to empty trend
      _weeklyTrend = [];
    }
  }

  /// Update nutrition goals (accepts NutritionGoals object)
  Future<void> updateGoalsObject(NutritionGoals newGoals) async {
    try {
      await _apiService.post('/nutrition/goals', newGoals.toJson());
      _goals = newGoals;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to update goals', tag: 'Nutrition', error: e);
      rethrow;
    }
  }

  /// Update nutrition goals with named parameters
  Future<void> updateGoals({
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? fiber,
    int? water,
  }) async {
    final newGoals = NutritionGoals(
      calories: calories ?? _goals.calories,
      protein: protein ?? _goals.protein,
      carbs: carbs ?? _goals.carbs,
      fat: fat ?? _goals.fat,
      fiber: fiber ?? _goals.fiber,
      water: water ?? _goals.water,
    );
    await updateGoalsObject(newGoals);
  }

  /// Set water goal (number of glasses)
  Future<void> setWaterGoal(int glasses) async {
    await updateGoals(water: glasses);
  }

  /// Log a meal
  Future<void> logMeal({
    required String mealName,
    required String mealType,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String? recipeId,
  }) async {
    try {
      final dateStr = _formatDate(DateTime.now());
      await _apiService.post('/nutrition/log-meal', {
        'mealName': mealName,
        'mealType': mealType,
        'date': dateStr,
        'nutrition': {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
        if (recipeId != null) 'recipe': recipeId,
      });

      // Reload daily nutrition
      await loadDailyNutrition(dateStr);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to log meal', tag: 'Nutrition', error: e);
      rethrow;
    }
  }

  /// Delete a meal log
  Future<void> deleteMeal(String mealId) async {
    try {
      await _apiService.delete('/nutrition/meals/$mealId');
      _todaysMeals.removeWhere((m) => m.id == mealId);

      // Reload to update totals
      await loadDailyNutrition();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to delete meal', tag: 'Nutrition', error: e);
      rethrow;
    }
  }

  /// Log water intake
  Future<void> logWaterIntake(int glasses) async {
    try {
      final dateStr = _formatDate(DateTime.now());
      await _apiService.post('/nutrition/water-intake', {
        'amount': glasses,
        'date': dateStr,
      });

      await loadDailyNutrition(dateStr);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to log water', tag: 'Nutrition', error: e);
      rethrow;
    }
  }

  /// Increment water by one glass
  Future<void> incrementWater() async {
    await logWaterIntake(waterGlasses + 1);
  }

  /// Decrement water by one glass
  Future<void> decrementWater() async {
    if (waterGlasses > 0) {
      await logWaterIntake(waterGlasses - 1);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
