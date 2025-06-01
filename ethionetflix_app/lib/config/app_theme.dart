// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main colors
  static const Color primaryColor = Color(0xFFE5FF00); // Yellow accent color
  static const Color backgroundColor =
      Color(0xFF000000); // Pure black background
  static const Color cardColor =
      Color(0xFF121212); // Slightly lighter black for cards
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
  static const Color buttonTextColor =
      Color(0xFF000000); // Black text on yellow buttons

  // Create the theme data
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.robotoTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: textColorPrimary,
      displayColor: textColorPrimary,
    );

    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textColorPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textColorPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColorTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textColorPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textColorPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textColorPrimary,
          fontSize: 16,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textColorSecondary,
          fontSize: 14,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textColorTertiary,
          fontSize: 12,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textColorSecondary,
        indicatorColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColorPrimary,
          side: const BorderSide(color: textColorPrimary),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return surfaceColor;
        }),
        checkColor: MaterialStateProperty.all(buttonTextColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceColor,
        thickness: 1,
      ),
    );
  }
}
