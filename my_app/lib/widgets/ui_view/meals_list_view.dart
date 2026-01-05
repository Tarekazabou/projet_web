import 'package:flutter/material.dart';

// ============================================================================
// MEALS LIST VIEW - Horizontal scrolling meal cards
// ============================================================================

class MealsListView extends StatefulWidget {
  const MealsListView({
    super.key,
    this.mainScreenAnimation,
    this.mainScreenAnimationController,
    this.meals,
    this.onMealTap,
  });

  final Animation<double>? mainScreenAnimation;
  final AnimationController? mainScreenAnimationController;
  final List<MealData>? meals;
  final Function(MealData)? onMealTap;

  @override
  State<MealsListView> createState() => _MealsListViewState();
}

class _MealsListViewState extends State<MealsListView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  List<MealData> get _meals => widget.meals ?? [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.mainScreenAnimationController!,
      builder: (context, _) {
        return FadeTransition(
          opacity: widget.mainScreenAnimation!,
          child: Transform.translate(
            offset: Offset(0, 30 * (1.0 - widget.mainScreenAnimation!.value)),
            child: SizedBox(
              height: 350,
              child: _meals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No meals yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first meal to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _meals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final animation = _createStaggeredAnimation(index);
                        return MealCard(
                          meal: _meals[index],
                          animation: animation,
                          onTap: () => widget.onMealTap?.call(_meals[index]),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Animation<double> _createStaggeredAnimation(int index) {
    final count = _meals.length.clamp(1, 10);
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (1 / count) * index * 0.5,
          0.5 + (1 / count) * index * 0.5,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

// ============================================================================
// MEAL CARD - Individual meal display card
// ============================================================================

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.animation,
    this.onTap,
  });

  final MealData meal;
  final Animation<double> animation;
  final VoidCallback? onTap;

  static const double _cardWidth = 160;
  static const double _iconSize = 70;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(50 * (1 - animation.value), 0),
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [_buildCardBody(), _buildIconBubble()],
        ),
      ),
    );
  }

  Widget _buildCardBody() {
    return Positioned.fill(
      top: _iconSize / 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [meal.startColor, meal.endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: meal.endColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 12),
            _buildMealsList(),
            const Spacer(),
            _buildNutritionInfo(),
            const SizedBox(height: 12),
            _buildCalories(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBubble() {
    return Positioned(
      top: 0,
      left: 8,
      child: Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          color: meal.endColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: meal.endColor.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(meal.icon, size: 36, color: Colors.white),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      meal.title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Colors.white,
        letterSpacing: 0.2,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMealsList() {
    final displayMeals = meal.meals?.take(3).toList() ?? [];
    return Text(
      displayMeals.join(', '),
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNutritionInfo() {
    return Row(
      children: [
        _buildNutrientTag('P', '${meal.protein}g'),
        const SizedBox(width: 8),
        _buildNutrientTag('C', '${meal.carbs}g'),
      ],
    );
  }

  Widget _buildNutrientTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalories() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${meal.kcal}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 36,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'kcal',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MEAL DATA MODEL
// ============================================================================

class MealData {
  const MealData({
    required this.icon,
    required this.title,
    required this.startColor,
    required this.endColor,
    this.meals,
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
  });

  final IconData icon;
  final String title;
  final Color startColor;
  final Color endColor;
  final List<String>? meals;
  final int kcal;
  final int protein;
  final int carbs;

  // Predefined meal types with their colors
  static const _breakfastColors = (Color(0xFFFA7D82), Color(0xFFFFB295));
  static const _lunchColors = (Color(0xFF738AE6), Color(0xFF5C5EDD));
  static const _dinnerColors = (Color(0xFF6F72CA), Color(0xFF1E1466));
  static const _snackColors = (Color(0xFFFE95B6), Color(0xFFFF5287));

  static List<MealData> defaultMeals = [
    MealData(
      icon: Icons.free_breakfast_rounded,
      title: 'Breakfast',
      kcal: 525,
      protein: 22,
      carbs: 65,
      meals: ['Bread', 'Peanut butter', 'Banana'],
      startColor: _breakfastColors.$1,
      endColor: _breakfastColors.$2,
    ),
    MealData(
      icon: Icons.lunch_dining_rounded,
      title: 'Lunch',
      kcal: 602,
      protein: 35,
      carbs: 58,
      meals: ['Salmon', 'Rice', 'Vegetables'],
      startColor: _lunchColors.$1,
      endColor: _lunchColors.$2,
    ),
    MealData(
      icon: Icons.dinner_dining_rounded,
      title: 'Dinner',
      kcal: 745,
      protein: 42,
      carbs: 72,
      meals: ['Chicken', 'Pasta', 'Salad'],
      startColor: _dinnerColors.$1,
      endColor: _dinnerColors.$2,
    ),
    MealData(
      icon: Icons.icecream_rounded,
      title: 'Snack',
      kcal: 125,
      protein: 8,
      carbs: 15,
      meals: ['Nuts', 'Yogurt'],
      startColor: _snackColors.$1,
      endColor: _snackColors.$2,
    ),
  ];
}
