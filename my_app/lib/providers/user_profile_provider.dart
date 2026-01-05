import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UserProfile {
  final int age;
  final double weight;
  final double height;
  final String dietarySensitivity;
  final int dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;

  UserProfile({
    required this.age,
    required this.weight,
    required this.height,
    required this.dietarySensitivity,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      dietarySensitivity: json['dietary_sensitivity'] ?? 'normal',
      dailyCalories: json['daily_calories'] ?? 2000,
      dailyProtein: (json['daily_protein'] as num?)?.toDouble() ?? 50,
      dailyCarbs: (json['daily_carbs'] as num?)?.toDouble() ?? 250,
      dailyFat: (json['daily_fat'] as num?)?.toDouble() ?? 65,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'weight': weight,
      'height': height,
      'dietary_sensitivity': dietarySensitivity,
      'daily_calories': dailyCalories,
      'daily_protein': dailyProtein,
      'daily_carbs': dailyCarbs,
      'daily_fat': dailyFat,
    };
  }
}

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isProfileComplete =>
      _userProfile != null && _userProfile?.age != 0;

  /// Calculate daily calorie needs using Harris-Benedict equation
  int _calculateDailyCalories(int age, double weight, double height, bool isMale) {
    double bmr;
    if (isMale) {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    // Moderate activity level (1.55)
    return (bmr * 1.55).toInt();
  }

  /// Calculate macro ratios based on dietary sensitivity
  Map<String, double> _calculateMacroRatios(String dietarySensitivity) {
    switch (dietarySensitivity) {
      case 'vegetarian':
        return {
          'protein': 1.0, // grams per kg
          'carbs': 3.5,
          'fat': 0.9,
        };
      case 'vegan':
        return {
          'protein': 1.2,
          'carbs': 3.5,
          'fat': 0.9,
        };
      case 'glutenFree':
      case 'dairyFree':
        return {
          'protein': 0.8,
          'carbs': 3.5,
          'fat': 0.8,
        };
      default:
        return {
          'protein': 0.8,
          'carbs': 3.5,
          'fat': 0.8,
        };
    }
  }

  Future<void> updateUserProfile({
    required int age,
    required double weight,
    required double height,
    required String dietarySensitivity,
    bool isMale = true,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Calculate daily calories
      final dailyCalories = _calculateDailyCalories(age, weight, height, isMale);

      // Calculate macro ratios
      final macroRatios = _calculateMacroRatios(dietarySensitivity);

      // Convert calories to grams (4 cal/g for protein & carbs, 9 cal/g for fat)
      final dailyProtein = weight * macroRatios['protein']!;
      final proteinCalories = dailyProtein * 4;

      final dailyFat = weight * macroRatios['fat']!;
      final fatCalories = dailyFat * 9;

      final carbCalories = dailyCalories - proteinCalories - fatCalories;
      final dailyCarbs = carbCalories / 4;

      _userProfile = UserProfile(
        age: age,
        weight: weight,
        height: height,
        dietarySensitivity: dietarySensitivity,
        dailyCalories: dailyCalories,
        dailyProtein: dailyProtein,
        dailyCarbs: dailyCarbs,
        dailyFat: dailyFat,
      );

      // Send to backend
      await ApiService().post(
        '/users/profile',
        _userProfile!.toJson(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadUserProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService().get('/users/profile');
      
      // If user doesn't have a profile yet (404 or empty response), leave _userProfile as null
      if (response != null && response.isNotEmpty) {
        _userProfile = UserProfile.fromJson(response);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // For new users who don't have a profile yet, this is expected
      // Just set loading to false and leave _userProfile as null
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _userProfile = null;
    _error = null;
    notifyListeners();
  }
}
