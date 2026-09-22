import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Figma FinTrack Palette
  static const Color background = Color(0xFFF8FAFC); // Clean soft background
  static const Color surface = Color(0xFFFFFFFF); // Card surface
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Light pill/chip bg
  
  // Brand Primary & Accents
  static const Color primary = Color(0xFFFA5533); // Vibrant Coral Orange from Figma (+Add Expense, CTAs)
  static const Color primaryHover = Color(0xFFE04523);
  static const Color primaryLight = Color(0xFFFFF2EF); // Coral tint
  static const Color secondary = Color(0xFF6366F1); // Indigo / Violet
  static const Color accent = Color(0xFF38BDF8); // Sky Blue
  
  // Financial Indicators
  static const Color green = Color(0xFF059669); // Emerald Green for +credits, positive balances
  static const Color greenLight = Color(0xFFECFDF5);
  static const Color greenBorder = Color(0xFFA7F3D0);
  
  static const Color red = Color(0xFFDC2626); // Red for -debits, you owe
  static const Color redLight = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);
  
  static const Color amber = Color(0xFFD97706); // Amber for alerts
  static const Color amberLight = Color(0xFFFFFBEB);
  
  static const Color blue = Color(0xFF2563EB); // Indigo/Blue for corporate, tags
  static const Color blueLight = Color(0xFFEFF6FF);
  
  // Neutrals & Surfaces
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A); // Deep slate
  static const Color textSecondary = Color(0xFF475569); // Mid slate
  static const Color textMuted = Color(0xFF94A3B8); // Light slate
  static const Color border = Color(0xFFE2E8F0); // Subtle border
  static const Color divider = Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.red,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
