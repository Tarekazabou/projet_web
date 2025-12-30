import 'package:flutter/material.dart';
import '../models/fridge_item.dart';
import '../services/api_service.dart';

class FridgeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<FridgeItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<FridgeItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFridgeItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getFridgeItems();
      _items = data.map((item) => FridgeItem.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String name,
    required String category,
    int quantity = 1,
    String unit = 'pieces',
    DateTime? expiryDate,
  }) async {
    try {
      final item = FridgeItem(
        ingredientName: name,
        category: category,
        quantity: quantity.toDouble(),
        unit: unit,
        expiryDate: expiryDate,
      );
      await _apiService.addFridgeItem(item.toJson());
      await loadFridgeItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItem(String? id) async {
    if (id == null) return;
    try {
      await _apiService.deleteFridgeItem(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(
    String? id, {
    String? name,
    int? quantity,
    String? category,
  }) async {
    if (id == null) return;
    try {
      final existingItem = _items.firstWhere((i) => i.id == id);
      final updatedItem = existingItem.copyWith(
        ingredientName: name,
        quantity: quantity?.toDouble(),
        category: category,
      );
      await _apiService.updateFridgeItem(id, updatedItem.toJson());
      await loadFridgeItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async => removeItem(id);
}
