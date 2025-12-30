import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Running/motivational view widget
/// Shows encouraging message with a visual element
class RunningView extends StatelessWidget {
  const RunningView({
    Key? key,
    this.animation,
    this.animationController,
    this.title = "You're doing great!",
    this.subtitle = 'Keep it up\nand stick to your plan!',
  }) : super(key: key);

  final Animation<double>? animation;
  final AnimationController? animationController;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation!.value),
              0.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: MealyTheme.nearlyGreen,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2EC4B6),
                      Color(0xFF40D9C9),
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
                      color: MealyTheme.nearlyGreen.withValues(alpha: 0.6),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: <Widget>[
                      // Illustration/Icon area
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: MealyTheme.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.emoji_food_beverage_rounded,
                          size: 48,
                          color: MealyTheme.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 0.0,
                                color: MealyTheme.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontFamily: MealyTheme.fontName,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  letterSpacing: 0.0,
                                  color: MealyTheme.white.withValues(alpha: 0.8),
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
            ),
          ),
        );
      },
    );
  }
}

/// Area/category grid list view
class AreaListView extends StatefulWidget {
  const AreaListView({
    Key? key,
    this.mainScreenAnimation,
    this.mainScreenAnimationController,
    this.items,
    this.onItemTap,
  }) : super(key: key);

  final Animation<double>? mainScreenAnimation;
  final AnimationController? mainScreenAnimationController;
  final List<AreaData>? items;
  final Function(AreaData)? onItemTap;

  @override
  State<AreaListView> createState() => _AreaListViewState();
}

class _AreaListViewState extends State<AreaListView>
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

  List<AreaData> get areaData => widget.items ?? AreaData.defaultItems;

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
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: GridView(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  children: List<Widget>.generate(
                    areaData.length,
                    (int index) {
                      final int count = areaData.length;
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
                      return AreaCard(
                        areaData: areaData[index],
                        animation: animation,
                        animationController: animationController,
                        onTap: () => widget.onItemTap?.call(areaData[index]),
                      );
                    },
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24.0,
                    crossAxisSpacing: 24.0,
                    childAspectRatio: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Area card widget
class AreaCard extends StatelessWidget {
  const AreaCard({
    Key? key,
    this.areaData,
    this.animationController,
    this.animation,
    this.onTap,
  }) : super(key: key);

  final AreaData? areaData;
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
              0.0,
              50 * (1.0 - animation!.value),
              0.0,
            ),
            child: InkWell(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: MealyTheme.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                    topRight: Radius.circular(48.0),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: HexColor(areaData!.startColor).withValues(alpha: 0.2),
                      offset: const Offset(1.1, 4.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  HexColor(areaData!.startColor),
                                  HexColor(areaData!.endColor),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              areaData!.icon,
                              color: MealyTheme.white,
                              size: 24,
                            ),
                          ),
                          // Progress indicator
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Stack(
                              children: <Widget>[
                                CircularProgressIndicator(
                                  value: areaData!.progress * animation!.value,
                                  strokeWidth: 3,
                                  backgroundColor: MealyTheme.background,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    HexColor(areaData!.startColor),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '${(areaData!.progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontFamily: MealyTheme.fontName,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: MealyTheme.darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            areaData!.title,
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.2,
                              color: MealyTheme.darkText,
                            ),
                          ),
                          Text(
                            areaData!.subtitle,
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              letterSpacing: 0.2,
                              color: MealyTheme.grey.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
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

/// Area data model
class AreaData {
  AreaData({
    this.icon = Icons.restaurant,
    this.title = '',
    this.subtitle = '',
    this.startColor = '#FA7D82',
    this.endColor = '#FFB295',
    this.progress = 0.0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String startColor;
  final String endColor;
  final double progress;

  static List<AreaData> defaultItems = <AreaData>[
    AreaData(
      icon: Icons.kitchen_rounded,
      title: 'Fridge',
      subtitle: '12 items',
      startColor: '#FA7D82',
      endColor: '#FFB295',
      progress: 0.65,
    ),
    AreaData(
      icon: Icons.restaurant_menu_rounded,
      title: 'Recipes',
      subtitle: '8 saved',
      startColor: '#738AE6',
      endColor: '#5C5EDD',
      progress: 0.45,
    ),
    AreaData(
      icon: Icons.calendar_today_rounded,
      title: 'Meal Plans',
      subtitle: '3 this week',
      startColor: '#FE95B6',
      endColor: '#FF5287',
      progress: 0.72,
    ),
    AreaData(
      icon: Icons.shopping_cart_rounded,
      title: 'Grocery',
      subtitle: '5 pending',
      startColor: '#6F72CA',
      endColor: '#1E1466',
      progress: 0.38,
    ),
  ];
}
