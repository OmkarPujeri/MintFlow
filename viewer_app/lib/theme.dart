import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// MintFlow viewer palette — dark & premium, built on the SAME mint brand green
/// used across the dashboard. Only the surfaces went dark; the mint values are
/// unchanged, just brightened variants added so mint reads on a dark canvas.
class AppColors {
  // Surfaces (deep green-black → layered for real depth, no flat white cards)
  static const background = Color(0xFF0C1512); // deep green-black canvas
  static const panel = Color(0xFF14201B); // card
  static const panelAlt = Color(0xFF1A2820); // input fill / elevated
  static const panelHi = Color(0xFF22342B); // pressed / hover

  // Text
  static const ink = Color(0xFFEAF3EC);
  static const muted = Color(0xFF93A69B);
  static const faint = Color(0xFF5F7369);

  // Lines
  static const line = Color(0xFF243530);
  static const lineSoft = Color(0xFF1C2A23);

  // Brand mint — UNCHANGED core, plus dark-tuned brights for text/glow.
  static const mint = Color(0xFF16A066); // brand green (same as dashboard)
  static const mintDark = Color(0xFF0D6844);
  static const mintDeep = Color(0xFF0A5236);
  static const mintBright = Color(0xFF2DD98A); // legible mint on dark
  static const mintGlow = Color(0xFF46E39B); // highlight / glow
  static const mintSoft = Color(0x242DD98A); // ~14% mint fill on dark

  // Accents kept from the existing scheme (used sparingly, as before).
  static const amber = Color(0xFFE7B24A); // streak flame / boosted only
  static const amberSoft = Color(0x22E7B24A);
  static const danger = Color(0xFFF0655E);
  static const dangerSoft = Color(0x22F0655E);

  /// Primary brand gradient — the coin, the logo, primary CTAs.
  static const brandGradient = LinearGradient(
    colors: [mintGlow, mint, mintDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Radial gradient for the minted coin face.
  static const coinGradient = RadialGradient(
    colors: [mintGlow, mint, mintDeep],
    center: Alignment(-0.35, -0.4),
    radius: 1.1,
    stops: [0.0, 0.55, 1.0],
  );
}

class AppRadii {
  static const card = 20.0;
  static const control = 14.0;
  static const pill = 999.0;
}

class AppShadows {
  /// Soft depth for cards on the dark canvas (darker + slightly larger than
  /// a light-theme shadow so it actually reads).
  static List<BoxShadow> get card => [
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ];

  /// Mint glow — for the coin and the balance hero.
  static List<BoxShadow> glow(double alpha) => [
        BoxShadow(
          color: AppColors.mintGlow.withValues(alpha: alpha),
          blurRadius: 34,
          spreadRadius: -6,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
}

ThemeData buildTheme() {
  final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
  final displayFont = GoogleFonts.plusJakartaSans();

  TextStyle heading(double size, {FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.5,
        height: 1.1,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.dark,
      primary: AppColors.mint,
      surface: AppColors.panel,
      surfaceTint: Colors.transparent,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: displayFont.fontFamily,
    textTheme: baseText.copyWith(
      headlineLarge: heading(32, weight: FontWeight.w800),
      headlineMedium: heading(26, weight: FontWeight.w800),
      titleLarge: heading(20, weight: FontWeight.w800),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(color: AppColors.muted, height: 1.45),
      bodySmall: GoogleFonts.inter(color: AppColors.muted, fontSize: 12.5),
    ),
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panelAlt,
      labelStyle: GoogleFonts.inter(color: AppColors.muted),
      helperStyle: GoogleFonts.inter(color: AppColors.faint, fontSize: 11.5),
      floatingLabelStyle: GoogleFonts.inter(color: AppColors.mintBright),
      prefixIconColor: AppColors.faint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        borderSide: const BorderSide(color: AppColors.mintBright, width: 1.6),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.panelAlt,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mintBright,
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.mintSoft,
      height: 68,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.mintBright
                : AppColors.faint,
            size: 24,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.mintBright
                : AppColors.faint,
          )),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.panelAlt,
      elevation: 12,
      surfaceTintColor: Colors.transparent,
      textStyle: GoogleFonts.inter(color: AppColors.ink, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.panelHi,
      contentTextStyle: GoogleFonts.inter(color: AppColors.ink),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.mintBright),
  );
}
