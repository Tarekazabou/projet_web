import 'package:flutter/material.dart';
import '../../utils/mealy_theme.dart';

/// Title view widget with title and action button
/// Inspired by fitness app title_view.dart
class TitleView extends StatelessWidget {
  const TitleView({
    Key? key,
    this.titleTxt = '',
    this.subTxt = '',
    this.animation,
    this.animationController,
    this.onTap,
  }) : super(key: key);

  final String titleTxt;
  final String subTxt;
  final Animation<double>? animation;
  final AnimationController? animationController;
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
              30 * (1.0 - animation!.value),
              0.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      titleTxt,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        color: MealyTheme.lightText,
                      ),
                    ),
                  ),
                  InkWell(
                    highlightColor: Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                    onTap: onTap ?? () {},
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: <Widget>[
                          Text(
                            subTxt,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color: MealyTheme.nearlyOrange,
                            ),
                          ),
                          const SizedBox(
                            height: 38,
                            width: 26,
                            child: Icon(
                              Icons.arrow_forward,
                              color: MealyTheme.darkText,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
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
}
