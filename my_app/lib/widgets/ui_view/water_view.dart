import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Water intake tracking view - Clean modern design
class WaterView extends StatelessWidget {
  const WaterView({
    super.key,
    this.animation,
    this.animationController,
    this.waterAmount = 0,
    this.waterGoal = 2000,
    this.onAddWater,
    this.onRemoveWater,
  });

  final Animation<double>? animation;
  final AnimationController? animationController;
  final int waterAmount;
  final int waterGoal;
  final VoidCallback? onAddWater;
  final VoidCallback? onRemoveWater;

  double get waterPercent => (waterAmount / waterGoal).clamp(0.0, 1.0);
  int get glassesConsumed => (waterAmount / 250).round();
  int get glassesGoal => (waterGoal / 250).round();

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, const Color(0xFFF0FAFA)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: MealyTheme.nearlyGreen.withValues(alpha: 0.15),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Left side - Stats and controls
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount display
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${(waterAmount * animation!.value).toInt()}',
                                  style: const TextStyle(
                                    fontFamily: MealyTheme.fontName,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 36,
                                    color: Color(0xFF2EC4B6),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ml',
                                  style: TextStyle(
                                    fontFamily: MealyTheme.fontName,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: const Color(
                                      0xFF2EC4B6,
                                    ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Goal text
                            Text(
                              'Goal: $waterGoal ml  •  $glassesConsumed/$glassesGoal glasses',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: MealyTheme.grey.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Progress bar
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2EC4B6,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    width:
                                        (MediaQuery.of(context).size.width -
                                            180) *
                                        waterPercent *
                                        animation!.value,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2EC4B6),
                                          Color(0xFF3DD9C9),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Control buttons
                            Row(
                              children: [
                                _WaterButton(
                                  icon: Icons.remove_rounded,
                                  onTap: onRemoveWater,
                                  isPrimary: false,
                                ),
                                const SizedBox(width: 12),
                                _WaterButton(
                                  icon: Icons.add_rounded,
                                  onTap: onAddWater,
                                  isPrimary: true,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '250ml / tap',
                                  style: TextStyle(
                                    fontFamily: MealyTheme.fontName,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: MealyTheme.grey.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right side - Water glass visualization
                      _WaterGlass(fillPercent: waterPercent * animation!.value),
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

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF2EC4B6)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF2EC4B6).withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : MealyTheme.grey,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _WaterGlass extends StatelessWidget {
  const _WaterGlass({required this.fillPercent});

  final double fillPercent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glass outline
          Container(
            width: 56,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          // Water fill
          Positioned(
            bottom: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: 52,
              height: (86 * fillPercent).clamp(0, 86),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3DD9C9).withValues(alpha: 0.7),
                    const Color(0xFF2EC4B6),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(fillPercent > 0.9 ? 4 : 2),
                  topRight: Radius.circular(fillPercent > 0.9 ? 4 : 2),
                  bottomLeft: const Radius.circular(22),
                  bottomRight: const Radius.circular(22),
                ),
              ),
            ),
          ),
          // Water drop icon
          Positioned(
            top: 12,
            child: Icon(
              Icons.water_drop_rounded,
              size: 24,
              color: const Color(
                0xFF2EC4B6,
              ).withValues(alpha: fillPercent > 0.7 ? 0.9 : 0.3),
            ),
          ),
          // Bubble effects when filled
          if (fillPercent > 0.3)
            Positioned(
              bottom: 20,
              left: 12,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (fillPercent > 0.5)
            Positioned(
              bottom: 35,
              right: 14,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
