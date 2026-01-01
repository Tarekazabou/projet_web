import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shopping_item.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class ShoppingListProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ShoppingItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ShoppingItem> get items => _items;
  List<ShoppingItem> get uncheckedItems => _items.where((item) => !item.isChecked).toList();
  List<ShoppingItem> get checkedItems => _items.where((item) => item.isChecked).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load shopping list from local storage
  Future<void> loadShoppingList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('shopping_list');
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _items = jsonList.map((json) => ShoppingItem.fromJson(json)).toList();
        AppLogger.info('Loaded ${_items.length} shopping items from storage', tag: 'Shopping');
      }
    } catch (e) {
      _error = 'Failed to load shopping list';
      AppLogger.error('Failed to load shopping list', tag: 'Shopping', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save shopping list to local storage
  Future<void> _saveShoppingList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('shopping_list', jsonString);
      AppLogger.info('Saved ${_items.length} shopping items to storage', tag: 'Shopping');
    } catch (e) {
      AppLogger.error('Failed to save shopping list', tag: 'Shopping', error: e);
    }
  }

  /// Add item to shopping list
  Future<void> addItem({
    required String name,
    String category = 'other',
    int quantity = 1,
    String unit = 'piece',
  }) async {
    try {
      final item = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        addedAt: DateTime.now(),
      );

      _items.add(item);
      await _saveShoppingList();
      notifyListeners();

      AppLogger.info('Added item to shopping list: $name', tag: 'Shopping');
    } catch (e) {
      _error = 'Failed to add item';
      AppLogger.error('Failed to add shopping item', tag: 'Shopping', error: e);
      notifyListeners();
    }
  }

  /// Remove item from shopping list
  Future<void> removeItem(String id) async {
    try {
      _items.removeWhere((item) => item.id == id);
      await _saveShoppingList();
      notifyListeners();

      AppLogger.info('Removed item from shopping list: $id', tag: 'Shopping');
    } catch (e) {
      _error = 'Failed to remove item';
      AppLogger.error('Failed to remove shopping item', tag: 'Shopping', error: e);
      notifyListeners();
    }
  }

  /// Toggle item checked status
  Future<void> toggleItemChecked(String id) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(
          isChecked: !_items[index].isChecked,
        );
        await _saveShoppingList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update item';
      AppLogger.error('Failed to toggle shopping item', tag: 'Shopping', error: e);
      notifyListeners();
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(String id, int quantity) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: quantity);
        await _saveShoppingList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update quantity';
      AppLogger.error('Failed to update item quantity', tag: 'Shopping', error: e);
      notifyListeners();
    }
  }

  /// Clear all checked items
  Future<void> clearCheckedItems() async {
    try {
      _items.removeWhere((item) => item.isChecked);
      await _saveShoppingList();
      notifyListeners();

      AppLogger.info('Cleared checked items from shopping list', tag: 'Shopping');
    } catch (e) {
      _error = 'Failed to clear checked items';
      AppLogger.error('Failed to clear checked items', tag: 'Shopping', error: e);
      notifyListeners();
    }
  }

  /// Generate shopping list based on user habits
  /// Analyzes recipe history and fridge depletion patterns
  Future<void> generateFromHabits(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This would call a backend endpoint that analyzes user data
      // For now, we'll add some common items based on analysis
      
      final commonItems = await _analyzeUserHabits(userId);
      
      for (final item in commonItems) {
        // Only add if not already in list
        if (!_items.any((existing) => existing.name.toLowerCase() == item['name'].toString().toLowerCase())) {
          _items.add(ShoppingItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + _items.length.toString(),
            name: item['name'],
            category: item['category'] ?? 'other',
            quantity: item['quantity'] ?? 1,
            unit: item['unit'] ?? 'piece',
            isFromHabits: true,
            addedAt: DateTime.now(),
          ));
        }
      }

      await _saveShoppingList();
      _isLoading = false;
      notifyListeners();

      AppLogger.success('Generated shopping list from habits', tag: 'Shopping');
    } catch (e) {
      _error = 'Failed to generate shopping list';
      AppLogger.error('Failed to generate shopping list', tag: 'Shopping', error: e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Analyze user habits to generate shopping suggestions
  Future<List<Map<String, dynamic>>> _analyzeUserHabits(String userId) async {
    try {
      // In a real implementation, this would:
      // 1. Fetch user's recipe history
      // 2. Analyze frequently used ingredients
      // 3. Check fridge depletion patterns
      // 4. Return suggested items to buy
      
      // For now, return some smart defaults based on common ingredients
      return [
        {'name': 'Milk', 'category': 'dairy', 'quantity': 1, 'unit': 'liter'},
        {'name': 'Eggs', 'category': 'protein', 'quantity': 12, 'unit': 'pieces'},
        {'name': 'Bread', 'category': 'grains', 'quantity': 1, 'unit': 'loaf'},
        {'name': 'Chicken Breast', 'category': 'protein', 'quantity': 500, 'unit': 'g'},
        {'name': 'Tomatoes', 'category': 'vegetables', 'quantity': 4, 'unit': 'pieces'},
        {'name': 'Onions', 'category': 'vegetables', 'quantity': 3, 'unit': 'pieces'},
        {'name': 'Rice', 'category': 'grains', 'quantity': 1, 'unit': 'kg'},
      ];
    } catch (e) {
      AppLogger.error('Failed to analyze user habits', tag: 'Shopping', error: e);
      return [];
    }
  }

  /// Get items by category
  Map<String, List<ShoppingItem>> getItemsByCategory() {
    final Map<String, List<ShoppingItem>> categorized = {};
    
    for (final item in _items) {
      if (!categorized.containsKey(item.category)) {
        categorized[item.category] = [];
      }
      categorized[item.category]!.add(item);
    }
    
    return categorized;
  }

  /// Get category icon
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return '🥬';
      case 'fruits':
        return '🍎';
      case 'protein':
      case 'meat':
        return '🍗';
      case 'dairy':
        return '🥛';
      case 'grains':
        return '🌾';
      case 'snacks':
        return '🍪';
      case 'beverages':
        return '🥤';
      case 'frozen':
        return '❄️';
      case 'bakery':
        return '🍞';
      default:
        return '🛒';
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
