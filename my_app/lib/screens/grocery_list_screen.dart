import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';
import '../utils/mealy_theme.dart';

class GroceryItem {
  final String name;
  final String quantity;
  final String unit;
  final String category;
  bool purchased;
  final double? inFridge;

  GroceryItem({
    required this.name,
    required this.quantity,
    this.unit = 'pcs',
    required this.category,
    this.purchased = false,
    this.inFridge,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] ?? '',
      quantity: json['quantity']?.toString() ?? '1',
      unit: json['unit'] ?? 'pcs',
      category: json['category'] ?? 'Other',
      purchased: json['purchased'] ?? false,
      inFridge: json['inFridge']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'purchased': purchased,
  };
}

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final ApiService _api = ApiService();
  List<GroceryItem> _items = [];
  // ignore: unused_field
  String? _listId;
  String _listName = 'My Grocery List';
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    'Fruits & Vegetables',
    'Dairy',
    'Meat & Fish',
    'Pantry',
    'Bakery',
    'Frozen',
    'Beverages',
    'Other',
  ];

  int get _itemsTotal => _items.length;
  int get _itemsPurchased => _items.where((item) => item.purchased).length;
  double get _progress =>
      _itemsTotal > 0 ? (_itemsPurchased / _itemsTotal) * 100 : 0;

  @override
  void initState() {
    super.initState();
    _loadGroceryItems();
  }

  Future<void> _loadGroceryItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.getGroceryItems();
      setState(() {
        _items = (response['items'] as List? ?? [])
            .map(
              (item) => GroceryItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        _listId = response['listId'];
        _listName = response['listName'] ?? 'My Grocery List';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePurchased(int index) async {
    try {
      await _api.toggleGroceryItemPurchased(index);
      setState(() {
        _items[index].purchased = !_items[index].purchased;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final item = _items[index];

    try {
      await _api.deleteGroceryItem(index);
      setState(() {
        _items.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${item.name} removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _addItem(
    String name,
    String quantity,
    String unit,
    String category,
  ) async {
    try {
      await _api.addGroceryItem({
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
      });
      await _loadGroceryItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
      }
    }
  }

  Future<void> _clearPurchased() async {
    try {
      await _api.clearPurchasedItems();
      await _loadGroceryItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchased items cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear: $e')));
      }
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedUnit = 'pcs';
    String selectedCategory = _categories[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g., Apples',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: ['pcs', 'kg', 'g', 'L', 'ml', 'pack']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setSheetState(() => selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedCategory = v!),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        _addItem(
                          nameController.text,
                          quantityController.text,
                          selectedUnit,
                          selectedCategory,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MealyTheme.nearlyOrange,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MealyTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              _buildError()
            else if (_items.isEmpty)
              _buildEmptyState()
            else ...[
              _buildProgressSection(),
              Expanded(child: _buildItemsList()),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: MealyTheme.nearlyOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grocery List',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
                Text(
                  _listName,
                  style: TextStyle(fontSize: 14.sp, color: MealyTheme.grey),
                ),
              ],
            ),
          ),
          if (_items.any((i) => i.purchased))
            IconButton(
              onPressed: _clearPurchased,
              icon: Icon(Icons.delete_sweep, color: Colors.red.shade400),
              tooltip: 'Clear purchased',
            ),
          IconButton(
            onPressed: _loadGroceryItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: MealyTheme.darkerText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$_itemsPurchased / $_itemsTotal items',
                    style: TextStyle(fontSize: 14.sp, color: MealyTheme.grey),
                  ),
                ],
              ),
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: MealyTheme.nearlyOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: MealyTheme.nearlyOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 10.h,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                MealyTheme.nearlyOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // Group items by category
    Map<String, List<MapEntry<int, GroceryItem>>> itemsByCategory = {};
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(MapEntry(i, item));
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: itemsByCategory.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(entry.key),
                    size: 20.r,
                    color: MealyTheme.nearlyOrange,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: MealyTheme.darkerText,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: MealyTheme.nearlyOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${entry.value.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: MealyTheme.nearlyOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map((e) => _buildItemCard(e.value, e.key)),
            SizedBox(height: 8.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(GroceryItem item, int index) {
    return Dismissible(
      key: Key('${item.name}_$index'),
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteItem(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: GestureDetector(
            onTap: () => _togglePurchased(index),
            child: Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: item.purchased
                    ? MealyTheme.nearlyOrange
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.purchased
                      ? MealyTheme.nearlyOrange
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: item.purchased
                  ? Icon(Icons.check, color: Colors.white, size: 18.r)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: item.purchased ? Colors.grey : MealyTheme.darkerText,
              decoration: item.purchased ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${item.quantity} ${item.unit}',
                style: TextStyle(fontSize: 14.sp, color: MealyTheme.grey),
              ),
              if (item.inFridge != null && item.inFridge! > 0) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${item.inFridge} in fridge',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
            onPressed: () => _deleteItem(index),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: MealyTheme.nearlyOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 64.r,
                  color: MealyTheme.nearlyOrange,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Your list is empty',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Add items to your grocery list or generate one from your meal plan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp, color: MealyTheme.grey),
              ),
              SizedBox(height: 30.h),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Item',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MealyTheme.nearlyOrange,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.r, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Failed to load grocery list',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: _loadGroceryItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fruits & Vegetables':
        return Icons.eco;
      case 'Dairy':
        return Icons.egg;
      case 'Meat & Fish':
        return Icons.set_meal;
      case 'Pantry':
        return Icons.kitchen;
      case 'Bakery':
        return Icons.bakery_dining;
      case 'Frozen':
        return Icons.ac_unit;
      case 'Beverages':
        return Icons.local_drink;
      default:
        return Icons.shopping_bag;
    }
  }
}
