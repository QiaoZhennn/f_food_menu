import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFF1E1E1E); // Dark background
  static const secondaryColor = Color(0xFF2D2D2D); // Slightly lighter dark
  static const accentColor = Color(0xFFE75C25); // Orange accent
  static const textColor = Colors.white;
  static const subtitleColor = Color(0xFFAAAAAA); // Gray for subtitles
  static const unselectedTabColor =
      Color(0xFFBBBBBB); // Lighter gray for better visibility

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: secondaryColor,
        background: primaryColor,
        onBackground: textColor,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      scaffoldBackgroundColor: primaryColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Rounded buttons
          ),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: subtitleColor,
          fontSize: 14,
        ),
      ),
      cardTheme: CardTheme(
        color: secondaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: secondaryColor,
        textColor: textColor,
        iconColor: accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: accentColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: unselectedTabColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedIconTheme: IconThemeData(
          color: accentColor,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: unselectedTabColor,
          size: 24,
        ),
      ),
    );
  }
}
