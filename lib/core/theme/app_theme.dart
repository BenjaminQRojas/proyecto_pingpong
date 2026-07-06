import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0ea5e9);
  static const Color primaryDark = Color(0xFF0284c7);
  static const Color secondary = Color(0xFFff6b35);
  static const Color success = Color(0xFF10b981);
  static const Color error = Color(0xFFef4444);
  static const Color background = Color(0xFF151922);
  static const Color backgroundDark = Color(0xFF0a0e14);
  static const Color surface = Color(0xFF1f2937);
  static const Color border = Color(0xFF2d3748);
  static const Color borderHover = Color(0xFF4b5563);
  static const Color textPrimary = Color(0xFFe5e9f0);
  static const Color textSecondary = Color(0xFF9ca3af);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: background, elevation: 0),
    cardTheme: CardThemeData(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: border,
      thumbColor: primary,
      overlayColor: primary.withOpacity(0.2),
      valueIndicatorColor: primary,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: primary.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primary);
        }
        return const IconThemeData(color: textSecondary);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primary, fontSize: 12);
        }
        return const TextStyle(color: textSecondary, fontSize: 12);
      }),
    ),
  );
}
