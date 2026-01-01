import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class OnboardingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  OnboardingData _data = OnboardingData();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  OnboardingData get data => _data;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLastStep => _currentStep >= 4;

  void updateGender(String gender) {
    _data.gender = gender;
    notifyListeners();
  }

  void updateWeight(double weight) {
    _data.weight = weight;
    notifyListeners();
  }

  void updateHeight(double height) {
    _data.height = height;
    notifyListeners();
  }

  void updateAllergies(List<String> allergies) {
    _data.allergies = allergies;
    notifyListeners();
  }

  void updateFridgeItems(List<String> items) {
    _data.fridgeItems = items;
    notifyListeners();
  }

  void updateDietType(String dietType) {
    _data.dietType = dietType;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void skipOnboarding() {
    _currentStep = 4; // Skip to end
    notifyListeners();
  }

  Future<bool> completeOnboarding(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('Completing onboarding for user: $userId', tag: 'Onboarding');

      // Calculate BMI and estimated nutrition goals
      if (_data.weight != null && _data.height != null) {
        final heightInMeters = _data.height! / 100;
        final bmi = _data.weight! / (heightInMeters * heightInMeters);
        
        // Estimate caloric needs based on basic parameters
        // This is a simplified calculation
        double calories = 2000;
        if (_data.gender == 'male') {
          calories = 2500;
        } else if (_data.gender == 'female') {
          calories = 2000;
        }

        _data.nutritionGoals = {
          'calories': calories.toInt(),
          'protein': (calories * 0.3 / 4).toInt(), // 30% from protein
          'carbs': (calories * 0.4 / 4).toInt(), // 40% from carbs
          'fat': (calories * 0.3 / 9).toInt(), // 30% from fat
          'fiber': 25,
          'water': 8,
        };
      }

      // Update user preferences
      final updateData = {
        'dietary_preferences': _data.dietType != null ? [_data.dietType] : [],
        'allergies': _data.allergies,
        'nutritionGoals': _data.nutritionGoals ?? {
          'calories': 2000,
          'protein': 150,
          'carbs': 250,
          'fat': 65,
          'fiber': 25,
          'water': 8,
        },
      };

      if (_data.weight != null) updateData['weight'] = _data.weight;
      if (_data.height != null) updateData['height'] = _data.height;
      if (_data.gender != null) updateData['gender'] = _data.gender;

      await _apiService.put('/users/$userId/preferences', updateData);

      // Add fridge items if any
      if (_data.fridgeItems.isNotEmpty) {
        for (final item in _data.fridgeItems) {
          try {
            await _apiService.addFridgeItem({
              'name': item,
              'ingredientName': item,
              'quantity': 1,
              'unit': 'piece',
              'category': 'other',
              'location': 'Main fridge',
            });
          } catch (e) {
            AppLogger.warning('Failed to add fridge item: $item', tag: 'Onboarding');
          }
        }
      }

      // Mark onboarding as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      _isLoading = false;
      notifyListeners();
      
      AppLogger.success('Onboarding completed successfully', tag: 'Onboarding');
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Onboarding failed', tag: 'Onboarding', error: e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _data = OnboardingData();
    _currentStep = 0;
    _error = null;
    notifyListeners();
  }
}
