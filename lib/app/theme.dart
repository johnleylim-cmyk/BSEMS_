import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium dark glassmorphic design system for BSEMS.
class AppTheme {
  AppTheme._();

  // ── Color Palette ───────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF111630);
  static const Color surfaceLight = Color(0xFF1A1F3D);
  static const Color card = Color(0xFF151A30);
  static const Color border = Color(0xFF2A2F4A);

  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFFB388FF);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentOrange = Color(0xFFFFAB40);
  static const Color accentRed = Color(0xFFFF5252);

  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted = Color(0xFF546E7A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentCyan, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x1A00E5FF), Color(0x1AB388FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF0D1127), Color(0xFF141937)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Radius ──────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ── Spacing ─────────────────────────────────────────────────────────
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ── Shadows ─────────────────────────────────────────────────────────
  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accentCyan.withValues(alpha: 0.15),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Theme Data ──────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentPurple,
        surface: surface,
        error: accentRed,
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: textPrimary,
        onError: Color(0xFFFFFFFF),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
            fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: accentCyan.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textPrimary),
        side: const BorderSide(color: border),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(color: border),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: textPrimary),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(3),
        thumbVisibility: WidgetStatePropertyAll(true),
      ),
    );
  }

  // ── Light Color Palette ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F2F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E4EA);
  static const Color lightTextPrimary = Color(0xFF1A1D2E);
  static const Color lightTextSecondary = Color(0xFF5A6178);
  static const Color lightTextMuted = Color(0xFF9098AD);

  static const LinearGradient lightSidebarGradient = LinearGradient(
    colors: [Color(0xFFF8F9FC), Color(0xFFEEF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Light Theme Data ────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: accentCyan,
        secondary: accentPurple,
        surface: lightSurface,
        error: accentRed,
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: lightTextPrimary,
        onError: Color(0xFFFFFFFF),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
            fontSize: 36, fontWeight: FontWeight.w700, color: lightTextPrimary),
        displayMedium: GoogleFonts.outfit(
            fontSize: 28, fontWeight: FontWeight.w700, color: lightTextPrimary),
        displaySmall: GoogleFonts.outfit(
            fontSize: 24, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineLarge: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineMedium: GoogleFonts.outfit(
            fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
        headlineSmall: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary),
        titleSmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: lightTextPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: lightTextSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: lightTextMuted),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 22, fontWeight: FontWeight.w600, color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentRed),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: lightTextMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceLight,
        selectedColor: accentCyan.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: lightTextPrimary),
        side: const BorderSide(color: lightBorder),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg)),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: lightSurfaceLight,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(color: lightBorder),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: lightTextPrimary),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(6),
        radius: Radius.circular(3),
        thumbVisibility: WidgetStatePropertyAll(true),
      ),
    );
  }

  // ── Theme-aware helpers ──────────────────────────────────────────────
  /// Returns context-appropriate colors based on current brightness.
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? background : lightBackground;
  static Color sfc(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;
  static Color sfcLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceLight : lightSurfaceLight;
  static Color crd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? card : lightCard;
  static Color brd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? border : lightBorder;
  static Color txtPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimary : lightTextPrimary;
  static Color txtSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : lightTextSecondary;
  static Color txtMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMuted : lightTextMuted;
  static LinearGradient sidebarGrad(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? sidebarGradient : lightSidebarGradient;
}
