// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Main colors
  static const Color primaryColor = Color(0xFFE5FF00); // Yellow accent color
  static const Color backgroundColor = Color(0xFF000000); // Pure black background
  static const Color cardColor = Color(0xFF121212); // Slightly lighter black for cards
  static const Color surfaceColor = Color(0xFF1E1E1E); // Dark surface color

  // Text colors
  static const Color textColorPrimary = Color(0xFFFFFFFF); // White
  static const Color textColorSecondary = Color(0xFFB3B3B3); // Light gray
  static const Color textColorTertiary = Color(0xFF757575); // Medium gray

  // Status colors
  static const Color errorColor = Color(0xFFFF5252); // Red for errors
  static const Color successColor = Color(0xFF4CAF50); // Green for success

  // Divider color
  static const Color dividerColor = Color(0xFF2A2A2A); // Dark gray for dividers

  // Button colors
  static const Color buttonColor = primaryColor;
  static const Color buttonTextColor = Color(0xFF000000); // Black text on yellow buttons

  // Card styling colors
  static const Color cardBorderColor = Color(0xFF333333); // Subtle border
  static const Color cardShadowColor = Color(0x40000000); // Shadow color

  // Cinematic font family
  static const String primaryFontFamily = 'SF Pro Display';
  static const String secondaryFontFamily = 'Montserrat';
  // Create the theme data
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColorPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: primaryFontFamily,
        ),
        iconTheme: IconThemeData(color: textColorPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColorTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textColorPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: primaryFontFamily,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          color: textColorPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
          letterSpacing: 0.3,
        ),
        titleSmall: TextStyle(
          color: textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: primaryFontFamily,
        ),
        bodyLarge: TextStyle(
          color: textColorPrimary,
          fontSize: 16,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: textColorSecondary,
          fontSize: 14,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textColorTertiary,
          fontSize: 12,
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w400,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textColorSecondary,
        labelStyle: const TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: secondaryFontFamily,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: cardShadowColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColorPrimary,
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: secondaryFontFamily,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: secondaryFontFamily,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return surfaceColor;
        }),
        checkColor: WidgetStateProperty.all(buttonTextColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(color: surfaceColor, thickness: 1),
    );
  }

  // Custom card decoration for movie cards
  static BoxDecoration get movieCardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: cardBorderColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: cardShadowColor,
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cardColor,
          cardColor.withOpacity(0.8),
        ],
        stops: const [0.0, 1.0],
      ),
    );
  }

  // Featured section card decoration
  static BoxDecoration get featuredCardDecoration {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: cardBorderColor.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: cardShadowColor,
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          backgroundColor.withOpacity(0.9),
        ],
        stops: const [0.0, 1.0],
      ),
    );
  }
}
