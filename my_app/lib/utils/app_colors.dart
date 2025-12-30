import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color paleGreen = Color(0xFF81C784);
  static const Color mintGreen = Color(0xFFA5D6A7);
  static const Color softGreen = Color(0xFFE8F5E9);

  // Beige/Cream Colors
  static const Color primaryBeige = Color(0xFFD7CCC8);
  static const Color secondaryBeige = Color(0xFFEFEBE9);
  static const Color accentBeige = Color(0xFFBCAAA4);

  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color lightOrange = Color(0xFFFFB74D);
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentRed = Color(0xFFE53935);

  // Neutral Colors
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textHint = Color(0xFFA0AEC0);

  // Background Colors
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
  );

  // Shadow Colors - using withValues for better precision
  static Color get shadowLight => Colors.black.withValues(alpha: 0.05);
  static Color get shadowMedium => Colors.black.withValues(alpha: 0.1);
  static Color get shadowDark => Colors.black.withValues(alpha: 0.15);

  // Helper method to get color with opacity
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
}
