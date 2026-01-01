import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Model for dashboard statistics
class DashboardStats {
  final int totalRecipes;
  final int mealsPlanned;
  final int fridgeItems;
  final int savedRecipes;
  final int expiringItems;

  DashboardStats({
    this.totalRecipes = 0,
    this.mealsPlanned = 0,
    this.fridgeItems = 0,
    this.savedRecipes = 0,
    this.expiringItems = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRecipes: json['totalRecipes'] ?? json['total_recipes'] ?? 0,
      mealsPlanned: json['mealsPlanned'] ?? json['meals_planned'] ?? 0,
      fridgeItems: json['fridgeItems'] ?? json['fridge_items'] ?? 0,
      savedRecipes: json['savedRecipes'] ?? json['saved_recipes'] ?? 0,
      expiringItems: json['expiringItems'] ?? json['expiring_items'] ?? 0,
    );
  }
}

/// Model for a quick action item
class QuickAction {
  final String id;
  final String label;
  final String icon;
  final String route;
  final bool isEnabled;

  QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.isEnabled = true,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? 'star',
      route: json['route'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'fridge':
      case 'kitchen':
        return Icons.kitchen;
      case 'recipe':
      case 'restaurant':
        return Icons.restaurant;
      case 'calendar':
      case 'schedule':
        return Icons.calendar_month;
      case 'grocery':
      case 'shopping':
        return Icons.shopping_cart;
      case 'nutrition':
      case 'health':
        return Icons.monitor_heart;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.star;
    }
  }
}

/// Model for a nutrition tip
class NutritionTip {
  final String id;
  final String title;
  final String description;
  final String? iconName;
  final String? category;

  NutritionTip({
    required this.id,
    required this.title,
    required this.description,
    this.iconName,
    this.category,
  });

  factory NutritionTip.fromJson(Map<String, dynamic> json) {
    return NutritionTip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon'],
      category: json['category'],
    );
  }

  IconData get icon {
    switch (iconName?.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'protein':
        return Icons.fitness_center;
      case 'vegetables':
      case 'veggies':
        return Icons.eco;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'sleep':
        return Icons.bedtime;
      case 'exercise':
        return Icons.directions_run;
      default:
        return Icons.lightbulb;
    }
  }
}

/// Provider for dashboard data
class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardStats _stats = DashboardStats();
  List<QuickAction> _quickActions = [];
  List<NutritionTip> _nutritionTips = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardStats get stats => _stats;
  List<QuickAction> get quickActions => _quickActions;
  List<NutritionTip> get nutritionTips => _nutritionTips;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convenient getters for stats
  int get totalRecipes => _stats.totalRecipes;
  int get mealsPlanned => _stats.mealsPlanned;
  int get fridgeItems => _stats.fridgeItems;
  int get savedRecipes => _stats.savedRecipes;
  int get expiringItems => _stats.expiringItems;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadStats(),
        loadQuickActions(),
        loadNutritionTips(),
        loadRecentActivity(),
      ]);
    } catch (e) {
      _error = e.toString();
      AppLogger.error(
        'Failed to load dashboard data',
        tag: 'Dashboard',
        error: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load dashboard statistics
  Future<void> loadStats() async {
    try {
      final response = await _apiService.get('/dashboard/stats');
      _stats = DashboardStats.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to load stats', tag: 'Dashboard', error: e);
      // Keep default stats on error
    }
  }

  /// Load quick actions configuration
  Future<void> loadQuickActions() async {
    try {
      final response = await _apiService.get('/dashboard/quick-actions');
      final actions = response['actions'] as List? ?? [];
      _quickActions = actions.map((a) => QuickAction.fromJson(a)).toList();
    } catch (e) {
      AppLogger.error(
        'Failed to load quick actions',
        tag: 'Dashboard',
        error: e,
      );
      // Use default actions
      _quickActions = _getDefaultQuickActions();
    }
  }

  /// Load nutrition tips
  Future<void> loadNutritionTips() async {
    try {
      final response = await _apiService.get('/dashboard/nutrition-tips');
      final tips = response['tips'] as List? ?? [];
      _nutritionTips = tips.map((t) => NutritionTip.fromJson(t)).toList();
    } catch (e) {
      AppLogger.error(
        'Failed to load nutrition tips',
        tag: 'Dashboard',
        error: e,
      );
      // Use default tips
      _nutritionTips = _getDefaultNutritionTips();
    }
  }

  /// Load recent activity
  Future<void> loadRecentActivity() async {
    try {
      final response = await _apiService.get('/dashboard/recent-activity');
      _recentActivity = List<Map<String, dynamic>>.from(
        response['activity'] ?? [],
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load recent activity',
        tag: 'Dashboard',
        error: e,
      );
      _recentActivity = [];
    }
  }

  /// Refresh all data
  Future<void> refresh() => loadDashboardData();

  List<QuickAction> _getDefaultQuickActions() {
    return [
      QuickAction(
        id: 'fridge',
        label: 'Mon Frigo',
        icon: 'fridge',
        route: '/fridge',
      ),
      QuickAction(
        id: 'recipes',
        label: 'Recettes',
        icon: 'recipe',
        route: '/recipes',
      ),
      QuickAction(
        id: 'meal_plan',
        label: 'Planning',
        icon: 'calendar',
        route: '/meal-plan',
      ),
      QuickAction(
        id: 'grocery',
        label: 'Courses',
        icon: 'grocery',
        route: '/grocery',
      ),
    ];
  }

  List<NutritionTip> _getDefaultNutritionTips() {
    return [
      NutritionTip(
        id: '1',
        title: 'Hydratation',
        description: 'Buvez au moins 8 verres d\'eau par jour',
        iconName: 'water',
      ),
      NutritionTip(
        id: '2',
        title: 'Protéines',
        description: 'Incluez des protéines à chaque repas',
        iconName: 'protein',
      ),
      NutritionTip(
        id: '3',
        title: 'Légumes',
        description: 'Mangez au moins 5 portions de fruits et légumes',
        iconName: 'vegetables',
      ),
    ];
  }
}
