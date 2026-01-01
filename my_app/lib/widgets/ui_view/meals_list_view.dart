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

  List<MealData> get _meals => widget.meals ?? MealData.defaultMeals;

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
              height: 200,
              child: ListView.separated(
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

  static const double _cardWidth = 140;
  static const double _iconSize = 80;

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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(48),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: meal.endColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 48, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 6),
            Expanded(child: _buildMealsList()),
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
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildMealsList() {
    final displayMeals = meal.meals?.take(2).toList() ?? [];
    return Text(
      displayMeals.join('\n'),
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.85),
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'kcal',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
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
  });

  final IconData icon;
  final String title;
  final Color startColor;
  final Color endColor;
  final List<String>? meals;
  final int kcal;

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
      meals: ['Bread', 'Peanut butter'],
      startColor: _breakfastColors.$1,
      endColor: _breakfastColors.$2,
    ),
    MealData(
      icon: Icons.lunch_dining_rounded,
      title: 'Lunch',
      kcal: 602,
      meals: ['Salmon', 'Rice'],
      startColor: _lunchColors.$1,
      endColor: _lunchColors.$2,
    ),
    MealData(
      icon: Icons.dinner_dining_rounded,
      title: 'Dinner',
      kcal: 745,
      meals: ['Chicken', 'Pasta'],
      startColor: _dinnerColors.$1,
      endColor: _dinnerColors.$2,
    ),
    MealData(
      icon: Icons.icecream_rounded,
      title: 'Snack',
      kcal: 125,
      meals: ['Nuts', 'Yogurt'],
      startColor: _snackColors.$1,
      endColor: _snackColors.$2,
    ),
  ];
}
