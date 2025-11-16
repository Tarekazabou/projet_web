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

  Future<void> addItem(FridgeItem item) async {
    try {
      await _apiService.addFridgeItem(item.toJson());
      await loadFridgeItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
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
}
