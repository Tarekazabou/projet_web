import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Mediterranean diet view - Main calorie/macro tracking card
/// Inspired by fitness app mediterranean_diet_view.dart
class DietView extends StatelessWidget {
  const DietView({
    Key? key,
    this.animation,
    this.animationController,
    this.caloriesEaten = 0,
    this.caloriesBurned = 0,
    this.caloriesGoal = 2000,
    this.carbsPercent = 0.0,
    this.proteinPercent = 0.0,
    this.fatPercent = 0.0,
  }) : super(key: key);

  final Animation<double>? animation;
  final AnimationController? animationController;
  final int caloriesEaten;
  final int caloriesBurned;
  final int caloriesGoal;
  final double carbsPercent;
  final double proteinPercent;
  final double fatPercent;

  int get caloriesLeft => (caloriesGoal - caloriesEaten + caloriesBurned).clamp(0, caloriesGoal);

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
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                              child: Column(
                                children: <Widget>[
                                  // Eaten row
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        height: 48,
                                        width: 2,
                                        decoration: BoxDecoration(
                                          color: HexColor('#87A0E5').withValues(alpha: 0.5),
                                          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(left: 4, bottom: 2),
                                              child: Text(
                                                'Eaten',
                                                style: TextStyle(
                                                  fontFamily: MealyTheme.fontName,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  letterSpacing: -0.1,
                                                  color: MealyTheme.grey.withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: <Widget>[
                                                SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: Icon(
                                                    Icons.restaurant_rounded,
                                                    color: HexColor('#87A0E5'),
                                                    size: 24,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                                                  child: Text(
                                                    '${(caloriesEaten * animation!.value).toInt()}',
                                                    style: const TextStyle(
                                                      fontFamily: MealyTheme.fontName,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: MealyTheme.darkerText,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                                                  child: Text(
                                                    'Kcal',
                                                    style: TextStyle(
                                                      fontFamily: MealyTheme.fontName,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                      letterSpacing: -0.2,
                                                      color: MealyTheme.grey.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Circle progress
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: MealyTheme.white,
                                        borderRadius: const BorderRadius.all(Radius.circular(100.0)),
                                        border: Border.all(
                                          width: 4,
                                          color: MealyTheme.nearlyOrange.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            '${(caloriesLeft * animation!.value).toInt()}',
                                            style: const TextStyle(
                                              fontFamily: MealyTheme.fontName,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 24,
                                              letterSpacing: 0.0,
                                              color: MealyTheme.nearlyOrange,
                                            ),
                                          ),
                                          Text(
                                            'Kcal left',
                                            style: TextStyle(
                                              fontFamily: MealyTheme.fontName,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 0.0,
                                              color: MealyTheme.grey.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: CustomPaint(
                                      painter: CurvePainter(
                                        colors: [
                                          MealyTheme.nearlyOrange,
                                          HexColor('#FF8F5C'),
                                        ],
                                        angle: 140 + (360 - 140) * (1 - caloriesLeft / caloriesGoal) * animation!.value,
                                      ),
                                      child: const SizedBox(
                                        width: 108,
                                        height: 108,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Macros row
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          color: MealyTheme.background,
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildMacroColumn('Carbs', carbsPercent, HexColor('#87A0E5')),
                          ),
                          Expanded(
                            child: _buildMacroColumn('Protein', proteinPercent, HexColor('#F56E98')),
                          ),
                          Expanded(
                            child: _buildMacroColumn('Fat', fatPercent, HexColor('#F1B440')),
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

  Widget _buildMacroColumn(String label, double percent, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: MealyTheme.fontName,
            fontWeight: FontWeight.w500,
            fontSize: 16,
            letterSpacing: -0.2,
            color: MealyTheme.darkText,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            height: 4,
            width: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: (70 * percent * animation!.value).clamp(0, 70),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.1), color],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${(percent * 100).toInt()}%',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: MealyTheme.grey.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for curved progress indicator
class CurvePainter extends CustomPainter {
  CurvePainter({
    this.colors,
    this.angle = 140,
  });

  final List<Color>? colors;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final shdowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    
    final shdowPaintCenter = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: shdowPaintCenter, radius: size.width / 2 - 4),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle)),
      false,
      shdowPaint,
    );

    shdowPaint.color = Colors.grey.withValues(alpha: 0.3);
    shdowPaint.strokeWidth = 16;
    canvas.drawArc(
      Rect.fromCircle(center: shdowPaintCenter, radius: size.width / 2 - 4),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle)),
      false,
      shdowPaint,
    );

    shdowPaint.color = Colors.grey.withValues(alpha: 0.2);
    shdowPaint.strokeWidth = 20;
    canvas.drawArc(
      Rect.fromCircle(center: shdowPaintCenter, radius: size.width / 2 - 4),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle)),
      false,
      shdowPaint,
    );

    shdowPaint.color = Colors.grey.withValues(alpha: 0.1);
    shdowPaint.strokeWidth = 22;
    canvas.drawArc(
      Rect.fromCircle(center: shdowPaintCenter, radius: size.width / 2 - 4),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle)),
      false,
      shdowPaint,
    );

    final rect = Rect.fromLTWH(0.0, 0.0, size.width, size.width);
    final gradient = SweepGradient(
      startAngle: degreeToRadians(268),
      endAngle: degreeToRadians(270.0 + 360),
      tileMode: TileMode.repeated,
      colors: colors!,
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 4),
      degreeToRadians(278),
      degreeToRadians(360 - (365 - angle)),
      false,
      paint,
    );

    final gradient1 = SweepGradient(
      tileMode: TileMode.repeated,
      colors: [Colors.white, Colors.white],
    );

    final cPaint = Paint();
    cPaint.shader = gradient1.createShader(rect);
    cPaint.color = Colors.white;
    cPaint.strokeWidth = 14 / 2;
    canvas.save();

    final centerToCircle = size.width / 2;
    canvas.save();

    canvas.translate(centerToCircle, centerToCircle);
    canvas.rotate(degreeToRadians(angle + 2));

    canvas.save();
    canvas.translate(0.0, -centerToCircle + 14 / 2);
    canvas.drawCircle(const Offset(0, 0), 14 / 5, cPaint);

    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double degreeToRadians(double degree) {
    return (math.pi / 180) * degree;
  }
}
