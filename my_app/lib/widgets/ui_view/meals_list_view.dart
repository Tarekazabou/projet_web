import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Meals list view - horizontal scrolling meal cards
/// Inspired by fitness app meals_list_view.dart
class MealsListView extends StatefulWidget {
  const MealsListView({
    Key? key,
    this.mainScreenAnimation,
    this.mainScreenAnimationController,
    this.meals,
    this.onMealTap,
  }) : super(key: key);

  final Animation<double>? mainScreenAnimation;
  final AnimationController? mainScreenAnimationController;
  final List<MealData>? meals;
  final Function(MealData)? onMealTap;

  @override
  State<MealsListView> createState() => _MealsListViewState();
}

class _MealsListViewState extends State<MealsListView>
    with TickerProviderStateMixin {
  AnimationController? animationController;

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    animationController?.forward();
    super.initState();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  List<MealData> get mealsData => widget.meals ?? MealData.defaultMeals;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.mainScreenAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.mainScreenAnimation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - widget.mainScreenAnimation!.value),
              0.0,
            ),
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 0, bottom: 0, right: 16, left: 16),
                itemCount: mealsData.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  final int count = mealsData.length > 10 ? 10 : mealsData.length;
                  final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animationController!,
                      curve: Interval(
                        (1 / count) * index,
                        1.0,
                        curve: Curves.fastOutSlowIn,
                      ),
                    ),
                  );
                  animationController?.forward();
                  return MealCard(
                    mealData: mealsData[index],
                    animation: animation,
                    animationController: animationController,
                    onTap: () => widget.onMealTap?.call(mealsData[index]),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual meal card
class MealCard extends StatelessWidget {
  const MealCard({
    Key? key,
    this.mealData,
    this.animationController,
    this.animation,
    this.onTap,
  }) : super(key: key);

  final MealData? mealData;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
              100 * (1.0 - animation!.value),
              0.0,
              0.0,
            ),
            child: InkWell(
              splashColor: Colors.transparent,
              onTap: onTap,
              child: SizedBox(
                width: 130,
                child: Stack(
                  children: <Widget>[
                    // Card background with gradient
                    Padding(
                      padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: HexColor(mealData!.endColor).withValues(alpha: 0.6),
                              offset: const Offset(1.1, 4.0),
                              blurRadius: 8.0,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: <Color>[
                              HexColor(mealData!.startColor),
                              HexColor(mealData!.endColor),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8.0),
                            bottomLeft: Radius.circular(8.0),
                            topLeft: Radius.circular(8.0),
                            topRight: Radius.circular(54.0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 54, left: 16, right: 16, bottom: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                mealData!.title,
                                style: const TextStyle(
                                  fontFamily: MealyTheme.fontName,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                  color: MealyTheme.white,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          mealData!.meals?.take(2).join('\n') ?? '',
                                          style: TextStyle(
                                            fontFamily: MealyTheme.fontName,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10,
                                            letterSpacing: 0.2,
                                            color: MealyTheme.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    '${mealData!.kcal}',
                                    style: const TextStyle(
                                      fontFamily: MealyTheme.fontName,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 24,
                                      letterSpacing: 0.2,
                                      color: MealyTheme.white,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, bottom: 3),
                                    child: Text(
                                      'kcal',
                                      style: TextStyle(
                                        fontFamily: MealyTheme.fontName,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                        letterSpacing: 0.2,
                                        color: MealyTheme.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top icon
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: MealyTheme.nearlyWhite.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            mealData!.icon,
                            size: 40,
                            color: MealyTheme.white,
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
      },
    );
  }
}

/// Meal data model
class MealData {
  MealData({
    this.icon = Icons.restaurant,
    this.title = '',
    this.startColor = '#FA7D82',
    this.endColor = '#FFB295',
    this.meals,
    this.kcal = 0,
  });

  final IconData icon;
  final String title;
  final String startColor;
  final String endColor;
  final List<String>? meals;
  final int kcal;

  static List<MealData> defaultMeals = <MealData>[
    MealData(
      icon: Icons.free_breakfast_rounded,
      title: 'Breakfast',
      kcal: 525,
      meals: <String>['Bread', 'Peanut butter', 'Apple'],
      startColor: '#FA7D82',
      endColor: '#FFB295',
    ),
    MealData(
      icon: Icons.lunch_dining_rounded,
      title: 'Lunch',
      kcal: 602,
      meals: <String>['Salmon', 'Rice', 'Vegetables'],
      startColor: '#738AE6',
      endColor: '#5C5EDD',
    ),
    MealData(
      icon: Icons.dinner_dining_rounded,
      title: 'Dinner',
      kcal: 745,
      meals: <String>['Chicken', 'Pasta', 'Salad'],
      startColor: '#6F72CA',
      endColor: '#1E1466',
    ),
    MealData(
      icon: Icons.icecream_rounded,
      title: 'Snack',
      kcal: 125,
      meals: <String>['Nuts', 'Yogurt'],
      startColor: '#FE95B6',
      endColor: '#FF5287',
    ),
  ];
}
