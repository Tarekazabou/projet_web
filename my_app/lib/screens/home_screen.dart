import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/mealy_theme.dart';
import '../widgets/ui_view/title_view.dart';
import '../widgets/ui_view/diet_view.dart';
import '../widgets/ui_view/water_view.dart';
import '../widgets/ui_view/meals_list_view.dart';
import '../widgets/ui_view/area_list_view.dart';
import '../providers/nutrition_provider.dart';
import '../providers/fridge_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/grocery_provider.dart';
import 'nutrition_screen.dart';
import 'fridge_screen.dart';
import 'recipe_generator_screen.dart';
import 'recipe_list_screen.dart';
import 'grocery_list_screen.dart';
import 'meal_planner_screen.dart';

/// Home screen - My Diary style
/// Inspired by fitness app my_diary_screen.dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.animationController}) : super(key: key);

  final AnimationController? animationController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;
  AnimationController? animationController;

  List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  @override
  void initState() {
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

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    super.initState();
  }

  Future<void> _loadData() async {
    final nutritionProvider = context.read<NutritionProvider>();
    final fridgeProvider = context.read<FridgeProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final groceryProvider = context.read<GroceryProvider>();

    await Future.wait([
      nutritionProvider.loadNutritionData(),
      fridgeProvider.loadFridgeItems(),
      dashboardProvider.loadDashboardData(),
      groceryProvider.loadGroceryItems(),
    ]);

    addAllListData();
    animationController?.forward();
  }

  void addAllListData() {
    listViews.clear();
    const int count = 9;

    // Title - Mediterranean diet
    listViews.add(
      TitleView(
        titleTxt: 'Today\'s Nutrition',
        subTxt: 'Details',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(
              (1 / count) * 0,
              1.0,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: animationController!,
        onTap: () => _navigateToNutritionDetails(),
      ),
    );

    // Diet view - Calorie tracking
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          return DietView(
            animation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval(
                  (1 / count) * 1,
                  1.0,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
            ),
            animationController: animationController!,
            caloriesEaten: nutrition.caloriesConsumed,
            caloriesBurned: 102,
            caloriesGoal: nutrition.caloriesGoal,
            carbsPercent: nutrition.carbsGoal > 0
                ? (nutrition.carbsConsumed / nutrition.carbsGoal).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0,
            proteinPercent: nutrition.proteinGoal > 0
                ? (nutrition.proteinConsumed / nutrition.proteinGoal).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0,
            fatPercent: nutrition.fatGoal > 0
                ? (nutrition.fatConsumed / nutrition.fatGoal).clamp(0.0, 1.0)
                : 0.0,
          );
        },
      ),
    );

    // Title - Meals
    listViews.add(
      TitleView(
        titleTxt: 'Meals today',
        subTxt: 'Add meal',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(
              (1 / count) * 2,
              1.0,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: animationController!,
        onTap: () => _showAddMealDialog(),
      ),
    );

    // Meals list view
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          final meals = nutrition.todaysMeals
              .map(
                (meal) => MealData(
                  icon: _getMealIcon(meal.mealType),
                  title: meal.mealName,
                  kcal: meal.calories,
                  meals: [
                    'P: ${meal.protein}g',
                    'C: ${meal.carbs}g',
                    'F: ${meal.fat}g',
                  ],
                  startColor: _getMealStartColor(meal.mealType),
                  endColor: _getMealEndColor(meal.mealType),
                ),
              )
              .toList();

          return MealsListView(
            mainScreenAnimation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval(
                  (1 / count) * 3,
                  1.0,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
            ),
            mainScreenAnimationController: animationController!,
            meals: meals.isEmpty ? null : meals,
          );
        },
      ),
    );

    // Title - Water
    listViews.add(
      TitleView(
        titleTxt: 'Water',
        subTxt: 'Aqua',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(
              (1 / count) * 4,
              1.0,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: animationController!,
        onTap: () => _showWaterGoalDialog(),
      ),
    );

    // Water view
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          return WaterView(
            animation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval(
                  (1 / count) * 5,
                  1.0,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
            ),
            animationController: animationController!,
            waterAmount: nutrition.waterGlasses * 250, // Convert glasses to ml
            waterGoal: nutrition.waterGoal * 250,
            onAddWater: () => nutrition.incrementWater(),
            onRemoveWater: () => nutrition.decrementWater(),
          );
        },
      ),
    );

    // Motivational view
    listViews.add(
      RunningView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(
              (1 / count) * 6,
              1.0,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: animationController!,
        title: "You're doing great!",
        subtitle: 'Keep tracking your meals\nand stay healthy!',
      ),
    );

    // Title - Quick access
    listViews.add(
      TitleView(
        titleTxt: 'Quick Access',
        subTxt: 'More',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(
              (1 / count) * 7,
              1.0,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        ),
        animationController: animationController!,
        onTap: () => _showQuickAccessSheet(),
      ),
    );

    // Area list view - Quick access grid
    listViews.add(
      Consumer3<FridgeProvider, DashboardProvider, GroceryProvider>(
        builder: (context, fridge, dashboard, grocery, _) {
          // Calculate dynamic progress values
          final fridgeProgress = fridge.items.length > 0 
              ? (fridge.items.length / 20).clamp(0.0, 1.0) 
              : 0.0;
          final recipesProgress = dashboard.stats.savedRecipes > 0
              ? (dashboard.stats.savedRecipes / 30).clamp(0.0, 1.0)
              : 0.0;
          final mealsProgress = dashboard.stats.mealsPlanned > 0
              ? (dashboard.stats.mealsPlanned / 7).clamp(0.0, 1.0)
              : 0.0;
          final groceryProgress = grocery.pendingItems > 0
              ? (grocery.pendingItems / 20).clamp(0.0, 1.0)
              : 0.0;
          
          final items = [
            AreaData(
              icon: Icons.kitchen_rounded,
              title: 'Fridge',
              subtitle: '${fridge.items.length} items',
              startColor: '#FA7D82',
              endColor: '#FFB295',
              progress: fridgeProgress,
            ),
            AreaData(
              icon: Icons.restaurant_menu_rounded,
              title: 'Recipes',
              subtitle: '${dashboard.stats.savedRecipes} saved',
              startColor: '#738AE6',
              endColor: '#5C5EDD',
              progress: recipesProgress,
            ),
            AreaData(
              icon: Icons.calendar_today_rounded,
              title: 'Meal Plans',
              subtitle: '${dashboard.stats.mealsPlanned} this week',
              startColor: '#FE95B6',
              endColor: '#FF5287',
              progress: mealsProgress,
            ),
            AreaData(
              icon: Icons.shopping_cart_rounded,
              title: 'Grocery',
              subtitle: '${grocery.pendingItems} pending',
              startColor: '#6F72CA',
              endColor: '#1E1466',
              progress: groceryProgress,
            ),
          ];

          return AreaListView(
            mainScreenAnimation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval(
                  (1 / count) * 8,
                  1.0,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
            ),
            mainScreenAnimationController: animationController!,
            items: items,
            onItemTap: (areaData) {
              Widget? screen;
              switch (areaData.title.toLowerCase()) {
                case 'fridge':
                  screen = const FridgeScreen();
                  break;
                case 'recipes':
                  screen = const RecipeListScreen();
                  break;
                case 'meal plans':
                  screen = const MealPlannerScreen();
                  break;
                case 'grocery':
                  screen = const GroceryListScreen();
                  break;
              }
              if (screen != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => screen!),
                );
              }
            },
          );
        },
      ),
    );

    setState(() {});
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.icecream_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Color _getMealStartColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFFA7D82);
      case 'lunch':
        return const Color(0xFF738AE6);
      case 'dinner':
        return const Color(0xFF6F72CA);
      case 'snack':
        return const Color(0xFFFE95B6);
      default:
        return const Color(0xFFFA7D82);
    }
  }

  Color _getMealEndColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFFFB295);
      case 'lunch':
        return const Color(0xFF5C5EDD);
      case 'dinner':
        return const Color(0xFF1E1466);
      case 'snack':
        return const Color(0xFFFF5287);
      default:
        return const Color(0xFFFFB295);
    }
  }

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  void _navigateToNutritionDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NutritionScreen(animationController: animationController),
      ),
    );
  }

  void _showAddMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMealBottomSheet(
        onMealAdded: () {
          // Refresh the data
          _loadData();
        },
      ),
    );
  }

  void _showWaterGoalDialog() {
    final nutritionProvider = context.read<NutritionProvider>();
    showDialog(
      context: context,
      builder: (context) => _WaterGoalDialog(
        currentGoal: nutritionProvider.waterGoal,
        currentIntake: nutritionProvider.waterGlasses,
        onGoalChanged: (newGoal) {
          nutritionProvider.setWaterGoal(newGoal);
        },
      ),
    );
  }

  void _showQuickAccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickAccessBottomSheet(
        onNavigate: (screen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      animationController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MealyTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            getMainListViewUI(),
            getAppBarUI(),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget getMainListViewUI() {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        top:
            AppBar().preferredSize.height +
            MediaQuery.of(context).padding.top +
            24,
        bottom: 62 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: listViews.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int index) {
        return listViews[index];
      },
    );
  }

  Widget getAppBarUI() {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: animationController!,
          builder: (BuildContext context, Widget? child) {
            return FadeTransition(
              opacity: topBarAnimation!,
              child: Transform(
                transform: Matrix4.translationValues(
                  0.0,
                  30 * (1.0 - topBarAnimation!.value),
                  0.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: MealyTheme.white.withValues(alpha: topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: MealyTheme.grey.withValues(
                          alpha: 0.4 * topBarOpacity,
                        ),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
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
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'My Diary',
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
                            // Date selector
                            SizedBox(
                              height: 38,
                              width: 38,
                              child: InkWell(
                                highlightColor: Colors.transparent,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(32.0),
                                ),
                                onTap: () {},
                                child: const Center(
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: MealyTheme.grey,
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
}

// ============================================================================
// ADD MEAL BOTTOM SHEET
// ============================================================================

class _AddMealBottomSheet extends StatefulWidget {
  final VoidCallback onMealAdded;

  const _AddMealBottomSheet({required this.onMealAdded});

  @override
  State<_AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends State<_AddMealBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _selectedMealType = 'breakfast';
  bool _isLoading = false;

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nutritionProvider = context.read<NutritionProvider>();
      await nutritionProvider.logMeal(
        mealName: _mealNameController.text.trim(),
        mealType: _selectedMealType,
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: int.tryParse(_proteinController.text) ?? 0,
        carbs: int.tryParse(_carbsController.text) ?? 0,
        fat: int.tryParse(_fatController.text) ?? 0,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onMealAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal added successfully!'),
            backgroundColor: MealyTheme.nearlyOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding meal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Add Meal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
              const SizedBox(height: 20),

              // Meal type selector
              Wrap(
                spacing: 8,
                children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                  final isSelected = _selectedMealType == type;
                  return ChoiceChip(
                    label: Text(type[0].toUpperCase() + type.substring(1)),
                    selected: isSelected,
                    selectedColor: MealyTheme.nearlyOrange.withValues(
                      alpha: 0.3,
                    ),
                    onSelected: (_) => setState(() => _selectedMealType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Meal name
              TextFormField(
                controller: _mealNameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Nutrition fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        border: OutlineInputBorder(),
                        suffixText: 'kcal',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat',
                        border: OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MealyTheme.nearlyOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Meal', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WATER GOAL DIALOG
// ============================================================================

class _WaterGoalDialog extends StatefulWidget {
  final int currentGoal;
  final int currentIntake;
  final ValueChanged<int> onGoalChanged;

  const _WaterGoalDialog({
    required this.currentGoal,
    required this.currentIntake,
    required this.onGoalChanged,
  });

  @override
  State<_WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<_WaterGoalDialog> {
  late int _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _goal > 0
        ? (widget.currentIntake / _goal * 100).clamp(0, 100)
        : 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.water_drop, color: Colors.blue),
          SizedBox(width: 8),
          Text('Water Intake'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2633C5), Color(0xFF6A88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.currentIntake} / $_goal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('glasses', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(0)}% of daily goal',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Goal adjuster
          const Text(
            'Daily Goal (glasses)',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _goal > 1 ? () => setState(() => _goal--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: MealyTheme.nearlyOrange,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_goal',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _goal < 20 ? () => setState(() => _goal++) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: MealyTheme.nearlyOrange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_goal * 250} ml',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onGoalChanged(_goal);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MealyTheme.nearlyOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ACCESS BOTTOM SHEET
// ============================================================================

class _QuickAccessBottomSheet extends StatelessWidget {
  final Function(Widget) onNavigate;

  const _QuickAccessBottomSheet({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        icon: Icons.kitchen_rounded,
        title: 'My Fridge',
        subtitle: 'Manage ingredients',
        color: const Color(0xFFFA7D82),
        onTap: () => onNavigate(const FridgeScreen()),
      ),
      _QuickAccessItem(
        icon: Icons.calendar_month_rounded,
        title: 'Meal Plans',
        subtitle: 'Weekly planning',
        color: const Color(0xFFFF6B35),
        onTap: () => onNavigate(const MealPlannerScreen()),
      ),
      _QuickAccessItem(
        icon: Icons.restaurant_menu_rounded,
        title: 'Recipes',
        subtitle: 'AI-powered recipes',
        color: const Color(0xFF738AE6),
        onTap: () => onNavigate(const RecipeGeneratorScreen()),
      ),
      _QuickAccessItem(
        icon: Icons.shopping_cart_rounded,
        title: 'Grocery',
        subtitle: 'Shopping items',
        color: const Color(0xFF6F72CA),
        onTap: () => onNavigate(const GroceryListScreen()),
      ),
      _QuickAccessItem(
        icon: Icons.analytics_rounded,
        title: 'Nutrition',
        subtitle: 'Track your diet',
        color: const Color(0xFF2EC4B6),
        onTap: () => onNavigate(const NutritionScreen()),
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MealyTheme.darkerText,
            ),
          ),
          const SizedBox(height: 16),
          // Scrollable list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: MealyTheme.darkerText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: MealyTheme.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
