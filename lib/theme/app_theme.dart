import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // Helper getters that dynamically return colors based on the current theme mode
  static Color get background => themeNotifier.value == ThemeMode.dark ? const Color(0xFF0A0F1D) : const Color(0xFFFCF9F2);
  static Color get surfaceCard => themeNotifier.value == ThemeMode.dark ? const Color(0xFF171E30) : const Color(0xFFFFFFFF);
  static Color get navBar => themeNotifier.value == ThemeMode.dark ? const Color(0xFF111625) : const Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF2979FF); // Premium brand blue
  static const Color safeGreen = Color(0xFF00C853);    // Vibrant green
  static const Color dangerRed = Color(0xFFEF5350);    // Refined alert red
  static const Color warningOrange = Color(0xFFFF9800); // Vibrant warning amber
  static Color get textPrimary => themeNotifier.value == ThemeMode.dark ? const Color(0xFFFFFFFF) : const Color(0xFF111111);
  static Color get textSecondary => themeNotifier.value == ThemeMode.dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get dividerColor => themeNotifier.value == ThemeMode.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // Rounded geometry layout parameters (premium, market-ready consumer aesthetic)
  static const double cardRadius = 16.0;
  static const double chipRadius = 24.0;
  static const double buttonRadius = 12.0;
  static const double horizontalPadding = 16.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0F1D),
      primaryColor: const Color(0xFF2979FF),
      cardColor: const Color(0xFF171E30),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF171E30),
        thickness: 1.0,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        titleLarge: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
          letterSpacing: 1.0,
          color: const Color(0xFFF8FAFC),
        ),
        titleMedium: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
          letterSpacing: 0.5,
          color: const Color(0xFFF8FAFC),
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          height: 1.4,
          color: const Color(0xFFF8FAFC),
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 12.0,
          height: 1.3,
          color: const Color(0xFF94A3B8),
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w700,
          fontSize: 10.0,
          letterSpacing: 1.2,
          color: const Color(0xFFF8FAFC),
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w500,
          fontSize: 9.0,
          letterSpacing: 0.8,
          color: const Color(0xFF94A3B8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0F1D),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111625),
        selectedItemColor: Color(0xFF2979FF),
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFCF9F2),
      primaryColor: const Color(0xFF2979FF),
      cardColor: const Color(0xFFFFFFFF),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1.0,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        titleLarge: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
          letterSpacing: 1.0,
          color: const Color(0xFF0F172A),
        ),
        titleMedium: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
          letterSpacing: 0.5,
          color: const Color(0xFF0F172A),
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          height: 1.4,
          color: const Color(0xFF0F172A),
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 12.0,
          height: 1.3,
          color: const Color(0xFF475569),
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w700,
          fontSize: 10.0,
          letterSpacing: 1.2,
          color: const Color(0xFF0F172A),
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontWeight: FontWeight.w500,
          fontSize: 9.0,
          letterSpacing: 0.8,
          color: const Color(0xFF475569),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF2979FF),
        unselectedItemColor: Color(0xFF475569),
        elevation: 0,
      ),
    );
  }
}
