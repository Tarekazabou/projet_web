import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/mealy_theme.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final ApiService _api = ApiService();
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now();

  Map<String, Map<String, List<Map<String, dynamic>>>> _weekPlans = {};
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _isLoading = true;
  bool _isLoadingSuggestions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(_selectedDate);
    _loadWeekPlans();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadWeekPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.getWeekMealPlans(
        startDate: DateFormat('yyyy-MM-dd').format(_weekStart),
      );

      setState(() {
        _weekPlans = {};
        final weekData = response['week_plans'] as Map<String, dynamic>? ?? {};
        weekData.forEach((date, meals) {
          _weekPlans[date] = {};
          (meals as Map<String, dynamic>).forEach((mealType, mealList) {
            _weekPlans[date]![mealType] = List<Map<String, dynamic>>.from(
              (mealList as List).map((m) => Map<String, dynamic>.from(m)),
            );
          });
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAISuggestions(String mealType) async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final response = await _api.getAIMealSuggestions(mealType: mealType);
      final data = response['data'] ?? response;
      setState(() {
        _aiSuggestions = List<Map<String, dynamic>>.from(
          data['suggestions'] ?? [],
        );
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() => _isLoadingSuggestions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load suggestions: $e')),
        );
      }
    }
  }

  Future<void> _addMealToPlan(
    String mealType,
    Map<String, dynamic> meal,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      await _api.createMealPlan({
        'planDate': dateStr,
        'mealType': mealType,
        'mealName': meal['name'],
        'calories': meal['calories'],
        'ingredients': meal['ingredients'] ?? [],
        'servings': 1,
      });

      await _loadWeekPlans();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${meal['name']} added to $mealType')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add meal: $e')));
      }
    }
  }

  Future<void> _deleteMeal(String planId) async {
    try {
      await _api.deleteMealPlan(planId);
      await _loadWeekPlans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  Future<void> _generateGroceryList() async {
    final endDate = _weekStart.add(const Duration(days: 6));

    try {
      final response = await _api.createGroceryFromMealPlan(
        DateFormat('yyyy-MM-dd').format(_weekStart),
        DateFormat('yyyy-MM-dd').format(endDate),
      );

      if (mounted) {
        final count = response['totalItems'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grocery list created with $count items!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate grocery list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MealyTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekSelector(),
            _buildDaySelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildError()
                  : _buildMealSections(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateGroceryList,
        backgroundColor: MealyTheme.nearlyOrange,
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: const Text(
          'Generate Grocery List',
          style: TextStyle(color: Colors.white),
        ),
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
                  'Meal Planner',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
                Text(
                  'Plan your weekly meals',
                  style: TextStyle(fontSize: 14.sp, color: MealyTheme.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadWeekPlans,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final endDate = _weekStart.add(const Duration(days: 6));
    final dateFormat = DateFormat('MMM d');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.subtract(const Duration(days: 7));
                _selectedDate = _weekStart;
              });
              _loadWeekPlans();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${dateFormat.format(_weekStart)} - ${dateFormat.format(endDate)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: MealyTheme.darkerText,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.add(const Duration(days: 7));
                _selectedDate = _weekStart;
              });
              _loadWeekPlans();
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 80.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _weekStart.add(Duration(days: index));
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 56.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isSelected ? MealyTheme.nearlyOrange : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: isToday && !isSelected
                    ? Border.all(color: MealyTheme.nearlyOrange, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? MealyTheme.nearlyOrange.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : MealyTheme.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : MealyTheme.darkerText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.r, color: Colors.red),
          SizedBox(height: 16.h),
          Text('Failed to load meal plans', style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 8.h),
          ElevatedButton(onPressed: _loadWeekPlans, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildMealSections() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayPlan =
        _weekPlans[dateStr] ??
        {'breakfast': [], 'lunch': [], 'dinner': [], 'snack': []};

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      children: [
        _buildMealSection(
          'Breakfast',
          'breakfast',
          Icons.free_breakfast_rounded,
          dayPlan['breakfast'] ?? [],
        ),
        SizedBox(height: 16.h),
        _buildMealSection(
          'Lunch',
          'lunch',
          Icons.lunch_dining_rounded,
          dayPlan['lunch'] ?? [],
        ),
        SizedBox(height: 16.h),
        _buildMealSection(
          'Dinner',
          'dinner',
          Icons.dinner_dining_rounded,
          dayPlan['dinner'] ?? [],
        ),
        SizedBox(height: 16.h),
        _buildMealSection(
          'Snacks',
          'snack',
          Icons.cookie_rounded,
          dayPlan['snack'] ?? [],
        ),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildMealSection(
    String title,
    String mealType,
    IconData icon,
    List<Map<String, dynamic>> meals,
  ) {
    final color = _getMealColor(mealType);

    return Container(
      padding: EdgeInsets.all(16.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showAddMealSheet(mealType),
                icon: Icon(Icons.add_circle, color: color, size: 28.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (meals.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: Text(
                  'No meals planned',
                  style: TextStyle(fontSize: 14.sp, color: MealyTheme.grey),
                ),
              ),
            )
          else
            ...meals.map((meal) => _buildMealCard(meal, color)),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, Color color) {
    final recipe = meal['recipe'] as Map<String, dynamic>? ?? {};
    final name = recipe['name'] ?? meal['mealName'] ?? 'Meal';
    final calories = recipe['calories'] ?? meal['calories'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: MealyTheme.darkerText,
                  ),
                ),
                if (calories > 0)
                  Text(
                    '$calories cal',
                    style: TextStyle(fontSize: 13.sp, color: MealyTheme.grey),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteMeal(meal['id']),
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade300,
              size: 22.r,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMealSheet(String mealType) {
    _loadAISuggestions(mealType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Add ${mealType[0].toUpperCase()}${mealType.substring(1)}',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildQuickAddSection(mealType),
              ),
              SizedBox(height: 16.h),
              const Divider(height: 1),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: MealyTheme.nearlyOrange,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'AI Suggestions',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoadingSuggestions)
                      SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: _isLoadingSuggestions
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        itemCount: _aiSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _aiSuggestions[index];
                          return _buildSuggestionCard(suggestion, mealType);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddSection(String mealType) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Add',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: MealyTheme.grey,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Meal name',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Cal',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    _addMealToPlan(mealType, {
                      'name': nameController.text,
                      'calories': int.tryParse(caloriesController.text) ?? 0,
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MealyTheme.nearlyOrange,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    Map<String, dynamic> suggestion,
    String mealType,
  ) {
    final matchPercent = suggestion['matchPercentage'] ?? 0;

    return GestureDetector(
      onTap: () => _showRecipeDetails(suggestion, mealType),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion['name'] ?? '',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14.r,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${suggestion['calories']} cal',
                        style: TextStyle(fontSize: 12.sp, color: MealyTheme.grey),
                      ),
                      SizedBox(width: 12.w),
                      Icon(Icons.timer, size: 14.r, color: MealyTheme.grey),
                      SizedBox(width: 4.w),
                      Text(
                        '${suggestion['prepTime']} min',
                        style: TextStyle(fontSize: 12.sp, color: MealyTheme.grey),
                      ),
                    ],
                  ),
                  if (matchPercent > 0) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$matchPercent% in fridge',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                _addMealToPlan(mealType, suggestion);
                Navigator.pop(context);
              },
              icon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: MealyTheme.nearlyOrange,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> suggestion, String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(24.w),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              
              // AI badge
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: MealyTheme.nearlyGreen,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 14.r),
                        SizedBox(width: 4.w),
                        Text(
                          'AI Suggested',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getMealColor(mealType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      mealType.toUpperCase(),
                      style: TextStyle(
                        color: _getMealColor(mealType),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Recipe title
              Text(
                suggestion['name'] ?? 'Recipe',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              
              // Description
              if (suggestion['description'] != null) ...[
                Text(
                  suggestion['description'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              
              // Quick info
              Row(
                children: [
                  _buildInfoChip(Icons.local_fire_department, '${suggestion['calories'] ?? 0} cal', Colors.orange),
                  SizedBox(width: 8.w),
                  _buildInfoChip(Icons.timer, '${suggestion['prepTime'] ?? 0} min', MealyTheme.nearlyGreen),
                  SizedBox(width: 8.w),
                  _buildInfoChip(Icons.bar_chart, suggestion['difficulty'] ?? 'medium', Colors.blue),
                ],
              ),
              SizedBox(height: 24.h),
              
              // Ingredients
              Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              ...((suggestion['ingredients'] as List<dynamic>?) ?? []).map((ingredient) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18.r, color: MealyTheme.nearlyGreen),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          ingredient.toString(),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 24.h),
              
              // Add to plan button
              ElevatedButton(
                onPressed: () {
                  _addMealToPlan(mealType, suggestion);
                  Navigator.pop(context); // Close recipe details
                  Navigator.pop(context); // Close add meal sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MealyTheme.nearlyOrange,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Add to $mealType',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFFFB74D);
      case 'lunch':
        return const Color(0xFF4CAF50);
      case 'dinner':
        return const Color(0xFF5C6BC0);
      case 'snack':
        return const Color(0xFFE91E63);
      default:
        return MealyTheme.nearlyOrange;
    }
  }
}
