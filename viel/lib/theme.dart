import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF141414);
  static const Color primaryAccent = Color(0xFF7153E7); // Purple
  static const Color secondaryAccent = Color(0xFFBBE753); // Lime
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF888888);
  static const Color mutedGrey = Color(0xFF2A2A2A);
  static const Color cardSurface = Color(0xFF1E1E1E);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryAccent,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
          titleLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5),
          titleMedium: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w500, fontSize: 16),
          bodyMedium: const TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w400, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: AppColors.mutedGrey, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.secondaryAccent,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
      ),
    );
  }
}
