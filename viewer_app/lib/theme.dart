import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised colour palette for the MintFlow company dashboard.
class AppColors {
  // Surfaces
  static const background = Color(0xFFF4F7F3);
  static const panel = Colors.white;
  static const panelAlt = Color(0xFFFBFDFB);

  // Text
  static const ink = Color(0xFF13201A);
  static const muted = Color(0xFF6B756F);
  static const faint = Color(0xFF9AA39D);

  // Lines
  static const line = Color(0xFFE4EAE4);
  static const lineSoft = Color(0xFFEDF2ED);

  // Brand mint
  static const mint = Color(0xFF16A066);
  static const mintDark = Color(0xFF0D6844);
  static const mintDeep = Color(0xFF0A5236);
  static const mintSoft = Color(0xFFE8F6EE);
  static const mintGlow = Color(0xFF3CD189);

  // Accents / semantics
  static const blue = Color(0xFF5E6DCD);
  static const blueSoft = Color(0xFFEFEFF9);
  static const amber = Color(0xFFE0A400);
  static const amberSoft = Color(0xFFFFF3CD);
  static const danger = Color(0xFFE0524B);
  static const dangerSoft = Color(0xFFFBE9E8);

  /// Primary brand gradient used on buttons, the logo, and hero accents.
  static const brandGradient = LinearGradient(
    colors: [mintGlow, mint, mintDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Chart palette (kept in a stable order for legends).
  static const chart = <Color>[
    mint,
    blue,
    amber,
    Color(0xFF3CD189),
    Color(0xFF7D8BF0),
  ];
}

/// Reusable design tokens so radii / shadows stay consistent.
class AppRadii {
  static const card = 16.0;
  static const control = 12.0;
  static const pill = 999.0;
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF13201A).withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: AppColors.mint.withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ];
}

class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
}

ThemeData buildTheme() {
  final baseText = GoogleFonts.interTextTheme();
  final displayFont = GoogleFonts.plusJakartaSans();

  TextStyle heading(double size, {FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.4,
        height: 1.1,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      primary: AppColors.mint,
      surface: AppColors.panel,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: displayFont.fontFamily,
    textTheme: baseText.copyWith(
      headlineLarge: heading(30, weight: FontWeight.w800),
      headlineMedium: heading(24, weight: FontWeight.w800),
      titleLarge: heading(19, weight: FontWeight.w800),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(color: AppColors.muted, height: 1.45),
      bodySmall: GoogleFonts.inter(color: AppColors.muted, fontSize: 12.5),
    ),
    dividerColor: AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panelAlt,
      labelStyle: GoogleFonts.inter(color: AppColors.muted),
      helperStyle: GoogleFonts.inter(color: AppColors.faint, fontSize: 11.5),
      floatingLabelStyle: GoogleFonts.inter(color: AppColors.mintDark),
      prefixIconColor: AppColors.faint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.mint, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.mintDark,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mintDark,
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: EdgeInsets.all(20),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.muted,
        fontWeight: FontWeight.w800,
        fontSize: 12.5,
      ),
      dataTextStyle: GoogleFonts.inter(color: AppColors.ink, fontSize: 13.5),
      dividerThickness: 1,
    ),
  );
}
