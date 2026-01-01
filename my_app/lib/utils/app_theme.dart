import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern, appetizing color palette for a food app
class AppTheme {
  AppTheme._();

  // Primary Brand Colors - Warm, appetizing tones
  static const Color primary = Color(0xFFFF6B35); // Vibrant orange
  static const Color primaryDark = Color(0xFFE55A2B);
  static const Color primaryLight = Color(0xFFFF8A5B);

  // Secondary Colors - Fresh & natural
  static const Color secondary = Color(0xFF2EC4B6); // Teal
  static const Color secondaryDark = Color(0xFF1A9E92);
  static const Color secondaryLight = Color(0xFF5DD9CD);

  // Accent Colors
  static const Color accent = Color(0xFFFFBF00); // Golden yellow
  static const Color accentLight = Color(0xFFFFD54F);

  // Background Colors - Clean & modern
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color cardDark = Color(0xFF1E1E2C);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A68);
  static const Color textMuted = Color(0xFF9898A9);
  static const Color textLight = Color(0xFF9898A9);  // Alias for muted
  static const Color textDark = Color(0xFF1A1A2E);   // Alias for primary
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF29B6F6);
  static const Color infoLight = Color(0xFFE1F5FE);

  // Nutrition Colors - Modern flat colors
  static const Color caloriesColor = Color(0xFFFF6B35);
  static const Color proteinColor = Color(0xFFE91E63);
  static const Color carbsColor = Color(0xFF3F51B5);
  static const Color fatColor = Color(0xFF8BC34A);
  static const Color fiberColor = Color(0xFF795548);
  static const Color waterColor = Color(0xFF03A9F4);

  // Category Colors
  static const Color vegetablesColor = Color(0xFF4CAF50);
  static const Color fruitsColor = Color(0xFFFF9800);
  static const Color meatColor = Color(0xFFE53935);
  static const Color dairyColor = Color(0xFF42A5F5);
  static const Color grainsColor = Color(0xFFFFEB3B);
  static const Color seafoodColor = Color(0xFF26C6DA);

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A5B)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2EC4B6), Color(0xFF5DD9CD)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A5B), Color(0xFFFFBF00)],
  );

  static const LinearGradient freshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2EC4B6), Color(0xFF4CAF50)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  // Card Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Border Radius
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 100;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  /// Get the main app theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primaryLight,
        secondary: secondary,
        secondaryContainer: secondaryLight,
        tertiary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryLight.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMuted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Extension for easy gradient text
extension GradientText on Text {
  Widget withGradient(Gradient gradient) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: this,
    );
  }
}
