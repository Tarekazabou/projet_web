import 'package:flutter/material.dart';

/// Mealy App Theme - Inspired by Best Flutter UI Templates Fitness App
/// A modern, appetizing design with warm food-focused colors
class MealyTheme {
  MealyTheme._();

  // Primary Colors - Warm, appetizing palette
  static const Color nearlyWhite = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F3F8);
  
  // Brand Colors - Food-inspired
  static const Color nearlyOrange = Color(0xFFFF6B35);  // Primary - Appetizing orange
  static const Color nearlyRed = Color(0xFFE84545);     // Accent - Tomato red
  static const Color nearlyGreen = Color(0xFF2EC4B6);   // Fresh - Herb green
  static const Color nearlyYellow = Color(0xFFFFBF00);  // Warm - Golden yellow
  
  // Gradient accent colors
  static const Color gradientStart = Color(0xFFFA7D82);
  static const Color gradientEnd = Color(0xFFFFB295);
  
  // Text Colors
  static const Color nearlyBlack = Color(0xFF213333);
  static const Color grey = Color(0xFF3A5160);
  static const Color darkGrey = Color(0xFF313A44);
  static const Color darkText = Color(0xFF253840);
  static const Color darkerText = Color(0xFF17262A);
  static const Color lightText = Color(0xFF4A6572);
  static const Color deactivatedText = Color(0xFF767676);
  static const Color dismissibleBackground = Color(0xFF364A54);
  static const Color spacer = Color(0xFFF2F2F2);
  
  // Font
  static const String fontName = 'Roboto';

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [nearlyOrange, Color(0xFFFFB295)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient freshGradient = LinearGradient(
    colors: [nearlyGreen, Color(0xFF89E5DC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [nearlyYellow, Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient breakfastGradient = LinearGradient(
    colors: [Color(0xFFFA7D82), Color(0xFFFFB295)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lunchGradient = LinearGradient(
    colors: [Color(0xFF738AE6), Color(0xFF5C5EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dinnerGradient = LinearGradient(
    colors: [Color(0xFF6F72CA), Color(0xFF1E1466)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient snackGradient = LinearGradient(
    colors: [Color(0xFFFE95B6), Color(0xFFFF5287)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Theme
  static const TextTheme textTheme = TextTheme(
    headlineMedium: display1,
    headlineSmall: headline,
    titleLarge: title,
    titleSmall: subtitle,
    bodyMedium: body2,
    bodyLarge: body1,
    bodySmall: caption,
  );

  static const TextStyle display1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 36,
    letterSpacing: 0.4,
    height: 0.9,
    color: darkerText,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
    color: darkerText,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 0.18,
    color: darkerText,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
    color: darkText,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
    color: darkText,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.05,
    color: darkText,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontName,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
    color: lightText,
  );

  /// Card decoration with shadow - signature look
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: white,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(8.0),
      bottomLeft: Radius.circular(8.0),
      bottomRight: Radius.circular(8.0),
      topRight: Radius.circular(68.0),
    ),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: grey.withValues(alpha: 0.2),
        offset: const Offset(1.1, 1.1),
        blurRadius: 10.0,
      ),
    ],
  );

  /// Standard card decoration
  static BoxDecoration get standardCardDecoration => BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(8.0),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: grey.withValues(alpha: 0.2),
        offset: const Offset(1.1, 1.1),
        blurRadius: 10.0,
      ),
    ],
  );

  /// Build light theme
  static ThemeData buildLightTheme() {
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(
      primary: nearlyOrange,
      secondary: nearlyGreen,
      surface: background,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: nearlyOrange,
      scaffoldBackgroundColor: background,
      fontFamily: fontName,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkerText),
        titleTextStyle: headline,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nearlyOrange,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: nearlyOrange,
        foregroundColor: white,
      ),
    );
  }
}

/// Hex color utility from the fitness app
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}
