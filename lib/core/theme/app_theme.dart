import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration
/// Enhanced Material Design 3 theme with dark mode support
class AppTheme {
  // Primary Colors (Health/Wellness themed)
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color tertiaryColor = Color(0xFF1F71CA);
  static const Color errorColor = Color(0xFFEA4335);
  static const Color warningColor = Color(0xFFFBBC04);
  
  // Glucose range colors
  static const Color glucoseHigh = Color(0xFFFFA726);
  static const Color glucoseNormal = Color(0xFF66BB6A);
  static const Color glucoseLow = Color(0xFFEF5350);
  static const Color glucoseVeryHigh = Color(0xFFE53935);
  
  // Background colors (Light)
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8EAED);
  
  // Background colors (Dark)
  static const Color darkBackgroundColor = Color(0xFF0F0F0F);
  static const Color darkSurfaceColor = Color(0xFF1C1C1C);
  static const Color darkCardColor = Color(0xFF2A2A2A);
  static const Color darkDividerColor = Color(0xFF3A3A3A);
  
  // Text colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
  
  // Dark text colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE8EAED);
  static const Color darkTextHint = Color(0xFF9AA0A6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.roboto(fontSize: 57, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.roboto(fontSize: 45, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500, color: textPrimary),
        titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, color: textHint),
        labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: textHint),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 1,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          textStyle: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dividerColor, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dividerColor, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.roboto(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.roboto(color: textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        unselectedLabelStyle: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w400),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        highlightElevation: 12,
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        subtitleTextStyle: GoogleFonts.roboto(color: textSecondary, fontSize: 12),
        selectedTileColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor.withValues(alpha: 0.5);
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: darkSurfaceColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.roboto(fontSize: 57, fontWeight: FontWeight.w700, color: darkTextPrimary),
        displayMedium: GoogleFonts.roboto(fontSize: 45, fontWeight: FontWeight.w700, color: darkTextPrimary),
        displaySmall: GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary),
        titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500, color: darkTextPrimary),
        titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextSecondary),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: darkTextSecondary),
        bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, color: darkTextHint),
        labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary),
        labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: darkTextHint),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 1,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          textStyle: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkDividerColor, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkDividerColor, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: errorColor, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.roboto(color: darkTextHint, fontSize: 14),
        labelStyle: GoogleFonts.roboto(color: darkTextSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        unselectedLabelStyle: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w400),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        highlightElevation: 12,
        sizeConstraints: const BoxConstraints.tightFor(width: 64, height: 64),
      ),
      listTileTheme: ListTileThemeData(
        textColor: darkTextPrimary,
        subtitleTextStyle: GoogleFonts.roboto(color: darkTextSecondary, fontSize: 12),
        selectedTileColor: primaryColor.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: darkDividerColor, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor;
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryColor.withValues(alpha: 0.5);
          return Colors.grey.shade800;
        }),
      ),
    );
  }
}
