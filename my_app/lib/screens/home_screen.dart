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
    animationController = widget.animationController ??
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
      } else if (scrollController.offset <= 24 && scrollController.offset >= 0) {
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

    await Future.wait([
      nutritionProvider.loadNutritionData(),
      fridgeProvider.loadFridgeItems(),
      dashboardProvider.loadDashboardData(),
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
            curve: const Interval((1 / count) * 0, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
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
                curve: const Interval((1 / count) * 1, 1.0, curve: Curves.fastOutSlowIn),
              ),
            ),
            animationController: animationController!,
            caloriesEaten: nutrition.caloriesConsumed,
            caloriesBurned: 102,
            caloriesGoal: nutrition.caloriesGoal,
            carbsPercent: nutrition.carbsGoal > 0
                ? (nutrition.carbsConsumed / nutrition.carbsGoal).clamp(0.0, 1.0)
                : 0.0,
            proteinPercent: nutrition.proteinGoal > 0
                ? (nutrition.proteinConsumed / nutrition.proteinGoal).clamp(0.0, 1.0)
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
            curve: const Interval((1 / count) * 2, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
        onTap: () {
          // Navigate to add meal
        },
      ),
    );

    // Meals list view
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          final meals = nutrition.todaysMeals
              .map((meal) => MealData(
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
                  ))
              .toList();

          return MealsListView(
            mainScreenAnimation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval((1 / count) * 3, 1.0, curve: Curves.fastOutSlowIn),
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
            curve: const Interval((1 / count) * 4, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
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
                curve: const Interval((1 / count) * 5, 1.0, curve: Curves.fastOutSlowIn),
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
            curve: const Interval((1 / count) * 6, 1.0, curve: Curves.fastOutSlowIn),
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
            curve: const Interval((1 / count) * 7, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
      ),
    );

    // Area list view - Quick access grid
    listViews.add(
      Consumer2<FridgeProvider, DashboardProvider>(
        builder: (context, fridge, dashboard, _) {
          final items = [
            AreaData(
              icon: Icons.kitchen_rounded,
              title: 'Fridge',
              subtitle: '${fridge.items.length} items',
              startColor: '#FA7D82',
              endColor: '#FFB295',
              progress: 0.65,
            ),
            AreaData(
              icon: Icons.restaurant_menu_rounded,
              title: 'Recipes',
              subtitle: '${dashboard.stats.savedRecipes} saved',
              startColor: '#738AE6',
              endColor: '#5C5EDD',
              progress: 0.45,
            ),
            AreaData(
              icon: Icons.calendar_today_rounded,
              title: 'Meal Plans',
              subtitle: '${dashboard.stats.mealsPlanned} this week',
              startColor: '#FE95B6',
              endColor: '#FF5287',
              progress: 0.72,
            ),
            AreaData(
              icon: Icons.shopping_cart_rounded,
              title: 'Grocery',
              subtitle: '${dashboard.stats.fridgeItems} pending',
              startColor: '#6F72CA',
              endColor: '#1E1466',
              progress: 0.38,
            ),
          ];

          return AreaListView(
            mainScreenAnimation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval((1 / count) * 8, 1.0, curve: Curves.fastOutSlowIn),
              ),
            ),
            mainScreenAnimationController: animationController!,
            items: items,
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

  String _getMealStartColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '#FA7D82';
      case 'lunch':
        return '#738AE6';
      case 'dinner':
        return '#6F72CA';
      case 'snack':
        return '#FE95B6';
      default:
        return '#FA7D82';
    }
  }

  String _getMealEndColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '#FFB295';
      case 'lunch':
        return '#5C5EDD';
      case 'dinner':
        return '#1E1466';
      case 'snack':
        return '#FF5287';
      default:
        return '#FFB295';
    }
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
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            )
          ],
        ),
      ),
    );
  }

  Widget getMainListViewUI() {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 24,
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
                        color: MealyTheme.grey.withValues(alpha: 0.4 * topBarOpacity),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).padding.top,
                      ),
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
                                borderRadius: const BorderRadius.all(Radius.circular(32.0)),
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
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }
}
