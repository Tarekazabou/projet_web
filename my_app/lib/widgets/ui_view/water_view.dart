import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Water intake tracking view
/// Inspired by fitness app water_view.dart
class WaterView extends StatelessWidget {
  const WaterView({
    Key? key,
    this.animation,
    this.animationController,
    this.waterAmount = 0,
    this.waterGoal = 2100,
    this.onAddWater,
    this.onRemoveWater,
  }) : super(key: key);

  final Animation<double>? animation;
  final AnimationController? animationController;
  final int waterAmount;
  final int waterGoal;
  final VoidCallback? onAddWater;
  final VoidCallback? onRemoveWater;

  double get waterPercent => (waterAmount / waterGoal).clamp(0.0, 1.0);

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
                  color: MealyTheme.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                    topRight: Radius.circular(68.0),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: MealyTheme.grey.withValues(alpha: 0.2),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                                      child: Text(
                                        '${(waterAmount * animation!.value).toInt()}',
                                        style: const TextStyle(
                                          fontFamily: MealyTheme.fontName,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 32,
                                          color: MealyTheme.nearlyGreen,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                                      child: Text(
                                        'ml',
                                        style: TextStyle(
                                          fontFamily: MealyTheme.fontName,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                          letterSpacing: -0.2,
                                          color: MealyTheme.nearlyGreen.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 2, bottom: 14),
                                  child: Text(
                                    'of daily goal $waterGoal ml',
                                    style: TextStyle(
                                      fontFamily: MealyTheme.fontName,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      letterSpacing: 0.0,
                                      color: MealyTheme.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 16),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: MealyTheme.nearlyGreen.withValues(alpha: 0.2),
                                  borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: (MediaQuery.of(context).size.width - 120) * waterPercent * animation!.value,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            MealyTheme.nearlyGreen.withValues(alpha: 0.1),
                                            MealyTheme.nearlyGreen,
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            // Add/Remove buttons
                            Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: Row(
                                children: <Widget>[
                                  _buildWaterButton(
                                    icon: Icons.remove,
                                    onTap: onRemoveWater,
                                    color: MealyTheme.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildWaterButton(
                                    icon: Icons.add,
                                    onTap: onAddWater,
                                    color: MealyTheme.nearlyGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Water glass icon
                      SizedBox(
                        width: 80,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            Container(
                              width: 60,
                              height: 100,
                              decoration: BoxDecoration(
                                color: MealyTheme.nearlyGreen.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              width: 60,
                              height: 100 * waterPercent * animation!.value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    MealyTheme.nearlyGreen.withValues(alpha: 0.6),
                                    MealyTheme.nearlyGreen,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              child: Icon(
                                Icons.water_drop_rounded,
                                size: 32,
                                color: MealyTheme.nearlyGreen.withValues(alpha: 0.4),
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

  Widget _buildWaterButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}
