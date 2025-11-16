import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBeige = Color(0xFFD7CCC8); // Warm creamy beige
  static const Color secondaryBeige = Color(0xFFEFEBE9); // Light creamy beige  
  static const Color accentBeige = Color(0xFFBCAAA4); // Soft taupe-beige
  
  // Complementary Colors
  static const Color accentOrange = Color(0xFFFF9800); // Warm orange
  static const Color accentYellow = Color(0xFFFFC107); // Golden yellow
  static const Color accentRed = Color(0xFFE53935); // Fresh tomato red
  
  // Neutral Colors
  static const Color darkText = Color(0xFF1A1A1A); // Almost black
  static const Color mediumText = Color(0xFF424242); // Dark grey
  static const Color lightText = Color(0xFF757575); // Medium grey
  static const Color hintText = Color(0xFF9E9E9E); // Light grey
  
  // Background Colors
  static const Color background = Color(0xFFF8FAF9); // Very light green-tinted white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards
  
  // Gradient Colors
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32), // Deep green
      Color(0xFF4CAF50), // Medium green
      Color(0xFF66BB6A), // Light green
    ],
  );
  
  static LinearGradient lightGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF81C784), // Light green
      Color(0xFFA5D6A7), // Very light green
    ],
  );
  
  static LinearGradient warmGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF9800), // Orange
      Color(0xFFFFB74D), // Light orange
    ],
  );
  
  // Semantic Colors
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF42A5F5);
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.05);
  static Color shadowMedium = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.15);
}
