import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Model for a grocery item
class GroceryItem {
  final String id;
  final String name;
  final String quantity;
  final String unit;
  final String category;
  bool purchased;

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit = 'pcs',
    required this.category,
    this.purchased = false,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity']?.toString() ?? '1',
      unit: json['unit'] ?? 'pcs',
      category: json['category'] ?? 'Other',
      purchased: json['purchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'purchased': purchased,
      };
}

/// Provider for grocery list management
class GroceryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<GroceryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _listId;
  String _listName = 'My Grocery List';

  // Getters
  List<GroceryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get listId => _listId;
  String get listName => _listName;

  // Calculated getters
  int get totalItems => _items.length;
  int get purchasedItems => _items.where((item) => item.purchased).length;
  int get pendingItems => _items.where((item) => !item.purchased).length;
  double get progress =>
      totalItems > 0 ? (purchasedItems / totalItems) * 100 : 0;

  /// Load grocery items from API
  Future<void> loadGroceryItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getGroceryItems();
      _items = (response['items'] as List? ?? [])
          .map((item) => GroceryItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _listId = response['listId'];
      _listName = response['listName'] ?? 'My Grocery List';
      _isLoading = false;
      _error = null;
      notifyListeners();

      AppLogger.info(
        'Loaded ${_items.length} grocery items (${pendingItems} pending)',
        tag: 'GroceryProvider',
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      AppLogger.error('Failed to load grocery items', tag: 'GroceryProvider', error: e);
      notifyListeners();
    }
  }

  /// Toggle item purchased status
  Future<void> togglePurchased(int index) async {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];
    final wasPurchased = item.purchased;

    // Optimistic update
    item.purchased = !item.purchased;
    notifyListeners();

    try {
      await _apiService.toggleGroceryItemPurchased(index);
    } catch (e) {
      // Revert on error
      item.purchased = wasPurchased;
      _error = e.toString();
      notifyListeners();
      AppLogger.error('Failed to update item', tag: 'GroceryProvider', error: e);
    }
  }

  /// Add a new grocery item
  Future<void> addItem(GroceryItem item) async {
    try {
      final response = await _apiService.addGroceryItem(item.toJson());
      final newItem = GroceryItem.fromJson(response['item']);
      _items.add(newItem);
      notifyListeners();
      AppLogger.info('Added grocery item: ${item.name}', tag: 'GroceryProvider');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to add item', tag: 'GroceryProvider', error: e);
      rethrow;
    }
  }

  /// Delete a grocery item
  Future<void> deleteItem(int index) async {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];

    // Optimistic update
    _items.removeAt(index);
    notifyListeners();

    try {
      await _apiService.deleteGroceryItem(index);
      AppLogger.info('Deleted grocery item: ${item.name}', tag: 'GroceryProvider');
    } catch (e) {
      // Revert on error
      _items.insert(index, item);
      _error = e.toString();
      notifyListeners();
      AppLogger.error('Failed to delete item', tag: 'GroceryProvider', error: e);
    }
  }

  /// Refresh grocery items
  Future<void> refresh() => loadGroceryItems();

  /// Clear all items
  void clear() {
    _items.clear();
    _listId = null;
    _listName = 'My Grocery List';
    notifyListeners();
  }
}
