import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GroceryItem {
  final String name;
  final String quantity;
  final String category;
  bool purchased;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.category,
    this.purchased = false,
  });
}

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final List<GroceryItem> items = [
    GroceryItem(
      name: 'Tomates',
      quantity: '500g',
      category: 'Fruits & Légumes',
      purchased: false,
    ),
    GroceryItem(
      name: 'Oeufs',
      quantity: '12 pièces',
      category: 'Produits laitiers',
      purchased: false,
    ),
  ];

  final List<String> categories = [
    'Fruits & Légumes',
    'Produits laitiers',
    'Viandes & Poissons',
    'Épicerie',
    'Boulangerie',
    'Surgelés',
    'Boissons',
    'Autres',
  ];

  int get itemsTotal => items.length;
  int get itemsPurchased => items.where((item) => item.purchased).length;
  double get progression =>
      itemsTotal > 0 ? (itemsPurchased / itemsTotal) * 100 : 0;

  void _togglePurchased(int index) {
    setState(() {
      items[index].purchased = !items[index].purchased;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String selectedCategory = categories[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajouter un article',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Article',
                  hintText: 'Ex: Pommes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  hintText: 'Ex: 1kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                setState(() {
                  items.add(
                    GroceryItem(
                      name: nameController.text,
                      quantity: quantityController.text,
                      category: selectedCategory,
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article ajouté avec succès')),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildProgressSection(),
                          Expanded(child: _buildItemsList()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 28.r),
          SizedBox(width: 12.w),
          Text(
            'Liste de Courses',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          if (items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () {
                setState(() {
                  items.removeWhere((item) => item.purchased);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Articles achetés supprimés')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                    'Progression',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$itemsPurchased / $itemsTotal articles',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 30.r,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  '${progression.toInt()}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progression / 100,
              minHeight: 12.h,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    // Group items by category
    Map<String, List<GroceryItem>> itemsByCategory = {};
    for (var item in items) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: itemsByCategory.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...entry.value.map((item) {
              final index = items.indexOf(item);
              return _buildItemCard(item, index);
            }),
            SizedBox(height: 12.h),
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
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteItem(index);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${item.name} supprimé')));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          leading: Checkbox(
            value: item.purchased,
            onChanged: (value) => _togglePurchased(index),
            shape: CircleBorder(),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: item.purchased ? Colors.grey : Colors.black87,
              decoration: item.purchased ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            item.quantity,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          trailing: Icon(Icons.drag_handle, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80.r,
              color: Colors.white.withOpacity(0.7),
            ),
            SizedBox(height: 20.h),
            Text(
              'Votre liste est vide',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Ajoutez des articles à votre liste de courses pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 30.h),
            ElevatedButton.icon(
              onPressed: _showAddItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un article'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
