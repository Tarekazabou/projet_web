import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/mealy_theme.dart';
import '../widgets/ui_view/title_view.dart';
import '../widgets/ui_view/diet_view.dart';
import '../widgets/ui_view/water_view.dart';
import '../providers/nutrition_provider.dart';

/// Nutrition tracking screen - Training style
/// Inspired by fitness app training_screen.dart
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key, this.animationController}) : super(key: key);

  final AnimationController? animationController;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with TickerProviderStateMixin {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    super.initState();
  }

  Future<void> _loadData() async {
    final nutritionProvider = context.read<NutritionProvider>();
    await nutritionProvider.loadNutritionData();
    addAllListData();
    animationController?.forward();
  }

  void addAllListData() {
    listViews.clear();
    const int count = 7;

    // Nutrition summary card
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          return _buildNutritionSummaryCard(
            animation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval((1 / count) * 0, 1.0,
                    curve: Curves.fastOutSlowIn),
              ),
            ),
            caloriesRemaining:
                nutrition.caloriesGoal - nutrition.caloriesConsumed,
            caloriesGoal: nutrition.caloriesGoal,
          );
        },
      ),
    );

    // Title - Calories
    listViews.add(
      TitleView(
        titleTxt: 'Calorie Breakdown',
        subTxt: 'Details',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval((1 / count) * 1, 1.0,
                curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
      ),
    );

    // Diet view
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          return DietView(
            animation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval((1 / count) * 2, 1.0,
                    curve: Curves.fastOutSlowIn),
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
                ? (nutrition.proteinConsumed / nutrition.proteinGoal)
                    .clamp(0.0, 1.0)
                : 0.0,
            fatPercent: nutrition.fatGoal > 0
                ? (nutrition.fatConsumed / nutrition.fatGoal).clamp(0.0, 1.0)
                : 0.0,
          );
        },
      ),
    );

    // Title - Hydration
    listViews.add(
      TitleView(
        titleTxt: 'Hydration',
        subTxt: 'Goal: 8 glasses',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval((1 / count) * 3, 1.0,
                curve: Curves.fastOutSlowIn),
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
                curve: const Interval((1 / count) * 4, 1.0,
                    curve: Curves.fastOutSlowIn),
              ),
            ),
            animationController: animationController!,
            waterAmount: nutrition.waterGlasses * 250,
            waterGoal: nutrition.waterGoal * 250,
            onAddWater: () => nutrition.incrementWater(),
            onRemoveWater: () => nutrition.decrementWater(),
          );
        },
      ),
    );

    // Title - Macros
    listViews.add(
      TitleView(
        titleTxt: 'Macro Goals',
        subTxt: 'Adjust',
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval((1 / count) * 5, 1.0,
                curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: animationController!,
        onTap: () => _showMacroGoalsDialog(),
      ),
    );

    // Macro goals grid
    listViews.add(
      Consumer<NutritionProvider>(
        builder: (context, nutrition, _) {
          return _buildMacroGoalsGrid(
            animation: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animationController!,
                curve: const Interval((1 / count) * 6, 1.0,
                    curve: Curves.fastOutSlowIn),
              ),
            ),
            carbsConsumed: nutrition.carbsConsumed,
            carbsGoal: nutrition.carbsGoal,
            proteinConsumed: nutrition.proteinConsumed,
            proteinGoal: nutrition.proteinGoal,
            fatConsumed: nutrition.fatConsumed,
            fatGoal: nutrition.fatGoal,
          );
        },
      ),
    );

    setState(() {});
  }

  Widget _buildNutritionSummaryCard({
    required Animation<double> animation,
    required int caloriesRemaining,
    required int caloriesGoal,
  }) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation.value),
              0.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      MealyTheme.nearlyOrange,
                      Color(0xFFFA7D82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                    topRight: Radius.circular(68.0),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: MealyTheme.grey.withValues(alpha: 0.6),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Today\'s Nutrition',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                          letterSpacing: 0.0,
                          color: MealyTheme.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          caloriesRemaining > 0
                              ? '$caloriesRemaining kcal remaining'
                              : '${-caloriesRemaining} kcal over goal',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            letterSpacing: 0.0,
                            color: MealyTheme.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: MealyTheme.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daily goal: $caloriesGoal kcal',
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: 0.0,
                              color: MealyTheme.white,
                            ),
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

  Widget _buildMacroGoalsGrid({
    required Animation<double> animation,
    required int carbsConsumed,
    required int carbsGoal,
    required int proteinConsumed,
    required int proteinGoal,
    required int fatConsumed,
    required int fatGoal,
  }) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation.value),
              0.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _buildMacroCard(
                      title: 'Carbs',
                      consumed: carbsConsumed,
                      goal: carbsGoal,
                      color: MealyTheme.nearlyOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMacroCard(
                      title: 'Protein',
                      consumed: proteinConsumed,
                      goal: proteinGoal,
                      color: MealyTheme.nearlyGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMacroCard(
                      title: 'Fat',
                      consumed: fatConsumed,
                      goal: fatGoal,
                      color: const Color(0xFF738AE6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroCard({
    required String title,
    required int consumed,
    required int goal,
    required Color color,
  }) {
    final percent = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: MealyTheme.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: MealyTheme.grey.withValues(alpha: 0.2),
            offset: const Offset(1.1, 1.1),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: MealyTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              width: 60,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        value: percent,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 6,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(percent * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${consumed}g',
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: MealyTheme.darkText,
              ),
            ),
            Text(
              'of ${goal}g',
              style: TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: MealyTheme.grey.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMacroGoalsDialog() {
    // TODO: Implement macro goals adjustment dialog
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
        top: AppBar().preferredSize.height +
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
                        color:
                            MealyTheme.grey.withValues(alpha: 0.4 * topBarOpacity),
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
                                  'Nutrition',
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
                            SizedBox(
                              height: 38,
                              width: 38,
                              child: InkWell(
                                highlightColor: Colors.transparent,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(32.0)),
                                onTap: () {},
                                child: const Center(
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    color: MealyTheme.nearlyOrange,
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
