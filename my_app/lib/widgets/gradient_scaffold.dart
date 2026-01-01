import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A reusable gradient scaffold for consistent app theming
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final List<Color>? gradientColors;
  final bool useSafeArea;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.gradientColors,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ?? [const Color(0xFF4CAF50), const Color(0xFF81C784)];

    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(child: body);
    }

    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: content,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// A custom app bar with gradient background
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
