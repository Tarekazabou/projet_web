import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fridge_item.dart';
import '../providers/fridge_provider.dart';
import '../utils/mealy_theme.dart';
import 'receipt_scanner_screen.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen>
    with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;
  AnimationController? animationController;
  double topBarOpacity = 0.0;
  String selectedCategory = 'All';
  final ScrollController scrollController = ScrollController();

  final List<String> categories = [
    'All',
    'Fruits',
    'Vegetables',
    'Dairy',
    'Meat',
    'Grains',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    animationController =
        widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        );

    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fridgeProvider = context.read<FridgeProvider>();
      await fridgeProvider.loadFridgeItems();
      animationController?.forward();
    });
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      animationController?.dispose();
    }
    scrollController.dispose();
    super.dispose();
  }

  List<FridgeItem> _getFilteredItems(List<FridgeItem> items) {
    if (selectedCategory == 'All') return items;
    return items
        .where(
          (item) =>
              item.category.toLowerCase() == selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MealyTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [_buildMainContent(), _buildTopBar()]),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: animationController!,
          builder: (context, child) {
            return FadeTransition(
              opacity: topBarAnimation!,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - topBarAnimation!.value)),
                child: Container(
                  decoration: BoxDecoration(
                    color: MealyTheme.white.withOpacity(topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.grey.withOpacity(0.4 * topBarOpacity),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16 - 8.0 * topBarOpacity,
                          bottom: 12 - 8.0 * topBarOpacity,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'My Fridge',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: MealyTheme.fontName,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22 + 6 - 6 * topBarOpacity,
                                    letterSpacing: 1.2,
                                    color: MealyTheme.darkerText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Consumer<FridgeProvider>(
      builder: (context, fridgeProvider, child) {
        if (fridgeProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: MealyTheme.nearlyOrange),
          );
        }

        final filteredItems = _getFilteredItems(fridgeProvider.items);

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 88,
            bottom: 100,
          ),
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 16),
            _buildSummaryCard(fridgeProvider.items),
            const SizedBox(height: 24),
            _buildItemsGrid(filteredItems, fridgeProvider),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.1, 0.6, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        backgroundColor: MealyTheme.white,
                        selectedColor: MealyTheme.nearlyOrange.withOpacity(0.2),
                        checkmarkColor: MealyTheme.nearlyOrange,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? MealyTheme.nearlyOrange
                              : MealyTheme.grey,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? MealyTheme.nearlyOrange
                                : MealyTheme.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(List<FridgeItem> items) {
    final expiringCount = items.where((item) => item.isExpiringSoon).length;
    final expiredCount = items.where((item) => item.isExpired).length;

    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.2, 0.7, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MealyTheme.nearlyOrange,
                      MealyTheme.nearlyOrange.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(68.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MealyTheme.nearlyOrange.withOpacity(0.4),
                      offset: const Offset(1.1, 4.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${items.length} Items',
                              style: const TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: MealyTheme.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'in your fridge',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: MealyTheme.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _buildStatusBadge(
                            '$expiredCount Expired',
                            Colors.red.shade100,
                            Colors.red.shade700,
                          ),
                          const SizedBox(height: 8),
                          _buildStatusBadge(
                            '$expiringCount Expiring Soon',
                            Colors.amber.shade100,
                            Colors.amber.shade800,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: MealyTheme.fontName,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildItemsGrid(List<FridgeItem> items, FridgeProvider provider) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(items[index], provider, index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.kitchen_outlined,
                  size: 80,
                  color: MealyTheme.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your fridge is empty',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MealyTheme.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add ingredients',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 14,
                    color: MealyTheme.grey.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(FridgeItem item, FridgeProvider provider, int index) {
    final categoryColor = _getCategoryColor(item.category);

    return GestureDetector(
      onTap: () => _showItemDetails(item, provider),
      child: Container(
        decoration: BoxDecoration(
          color: MealyTheme.white,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(8.0),
            bottomLeft: Radius.circular(8.0),
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(54.0),
          ),
          boxShadow: [
            BoxShadow(
              color: MealyTheme.grey.withOpacity(0.2),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(54.0),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 32,
                      color: MealyTheme.white.withOpacity(0.6),
                    ),
                  ),
                  if (item.isExpired || item.isExpiringSoon)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.isExpired
                              ? Colors.red.shade600
                              : Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.isExpired ? 'Expired' : 'Soon',
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: MealyTheme.darkerText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.formattedQuantity,
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 12,
                            color: MealyTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: item.isExpired
                              ? Colors.red
                              : item.isExpiringSoon
                              ? Colors.amber
                              : MealyTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.expiryStatusText,
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontSize: 11,
                              color: item.isExpired
                                  ? Colors.red
                                  : item.isExpiringSoon
                                  ? Colors.amber.shade800
                                  : MealyTheme.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return const Color(0xFFFA7D82);
      case 'vegetables':
        return const Color(0xFF738AE6);
      case 'dairy':
        return const Color(0xFFFEB95A);
      case 'meat':
        return const Color(0xFFE57373);
      case 'grains':
        return const Color(0xFF81C784);
      default:
        return const Color(0xFF6F72CA);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.egg;
      case 'meat':
        return Icons.set_meal;
      case 'grains':
        return Icons.grass;
      default:
        return Icons.kitchen;
    }
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
          ),
        );
        return ScaleTransition(
          scale: animation,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 50,
              right: 4,
            ),
            child: FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: MealyTheme.nearlyOrange,
              child: const Icon(Icons.add, color: MealyTheme.white),
            ),
          ),
        );
      },
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MealyTheme.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Add Items to Fridge',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: MealyTheme.darkerText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Add manually option
              _buildAddOptionItem(
                icon: Icons.edit,
                title: 'Add Item Manually',
                subtitle: 'Enter item details yourself',
                color: MealyTheme.nearlyOrange,
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog();
                },
              ),
              const Divider(height: 1, indent: 72),
              // Scan receipt option
              _buildAddOptionItem(
                icon: Icons.receipt_long,
                title: 'Add Items with Shopping Receipt',
                subtitle: 'Scan a receipt to auto-add items',
                color: MealyTheme.nearlyGreen,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReceiptScannerScreen(),
                    ),
                  ).then((_) {
                    // Refresh fridge items when returning from receipt scanner
                    context.read<FridgeProvider>().loadFridgeItems();
                  });
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: MealyTheme.darkerText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 12,
                      color: MealyTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: MealyTheme.grey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(FridgeItem item, FridgeProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MealyTheme.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(item.category),
                            _getCategoryColor(item.category).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: MealyTheme.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: MealyTheme.darkerText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontSize: 14,
                              color: MealyTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(item, provider);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.inventory_2,
                      'Quantity',
                      item.formattedQuantity,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.access_time,
                      'Expiry',
                      item.expiryStatusText,
                    ),
                    if (item.expiryDate != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Expiry Date',
                        '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MealyTheme.nearlyOrange),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: MealyTheme.fontName,
            fontSize: 14,
            color: MealyTheme.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: MealyTheme.fontName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MealyTheme.darkerText,
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedCat = 'Fruits';
    String selectedUnit = 'pieces';
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Add Ingredient',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.w700,
              color: MealyTheme.darkerText,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['pieces', 'kg', 'g', 'L', 'ml', 'cups']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCat = v!),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => expirationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiration Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      expirationDate != null
                          ? '${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}'
                          : 'Tap to select',
                      style: TextStyle(
                        color: expirationDate != null
                            ? MealyTheme.darkerText
                            : MealyTheme.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  final provider = context.read<FridgeProvider>();
                  provider.addItem(
                    name: nameController.text,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                    unit: selectedUnit,
                    category: selectedCat,
                    expiryDate: expirationDate,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MealyTheme.nearlyOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(FridgeItem item, FridgeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeItem(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
