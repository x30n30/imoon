import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour palette ───────────────────────────────────────────────────────────

class IMoonColors {
  // Backgrounds
  static const bg          = Color(0xFF0D0F1A);
  static const surface     = Color(0xFF161829);
  static const surfaceVar  = Color(0xFF1E2138);
  static const border      = Color(0xFF2A2D45);

  // Accent
  static const primary     = Color(0xFFF4A7B9); // soft rose
  static const primaryDim  = Color(0x33F4A7B9);
  static const secondary   = Color(0xFFB39DDB); // lavender
  static const secondaryDim= Color(0x33B39DDB);

  // Semantic — cycle phases
  static const period      = Color(0xFFE8759A); // period days
  static const periodDim   = Color(0x44E8759A);
  static const fertile     = Color(0xFF80CBC4); // fertile window
  static const fertileDim  = Color(0x4480CBC4);
  static const ovulation   = Color(0xFFFFD54F); // ovulation day
  static const ovulationDim= Color(0x44FFD54F);
  static const predicted   = Color(0xFFF8BBD9); // predicted period
  static const predictedDim= Color(0x33F8BBD9);

  // Text
  static const textPrimary = Color(0xFFF0E6EF);
  static const textMuted   = Color(0xFF8B8FAF);
  static const textDim     = Color(0xFF4A4D6A);

  // Utility
  static const ok          = Color(0xFF80CBC4);
  static const warn        = Color(0xFFFFD54F);
  static const bad         = Color(0xFFEF9A9A);
}

// ── Phase colours helper ─────────────────────────────────────────────────────

Color phaseColor(CyclePhaseUI phase) => switch (phase) {
  CyclePhaseUI.menstrual  => IMoonColors.period,
  CyclePhaseUI.follicular => IMoonColors.secondary,
  CyclePhaseUI.ovulation  => IMoonColors.ovulation,
  CyclePhaseUI.luteal     => IMoonColors.primary,
  CyclePhaseUI.unknown    => IMoonColors.textMuted,
};

Color phaseDimColor(CyclePhaseUI phase) => switch (phase) {
  CyclePhaseUI.menstrual  => IMoonColors.periodDim,
  CyclePhaseUI.follicular => IMoonColors.secondaryDim,
  CyclePhaseUI.ovulation  => IMoonColors.ovulationDim,
  CyclePhaseUI.luteal     => IMoonColors.primaryDim,
  CyclePhaseUI.unknown    => IMoonColors.border,
};

String phaseLabel(CyclePhaseUI phase) => switch (phase) {
  CyclePhaseUI.menstrual  => 'Menstrual',
  CyclePhaseUI.follicular => 'Follicular',
  CyclePhaseUI.ovulation  => 'Ovulation',
  CyclePhaseUI.luteal     => 'Luteal',
  CyclePhaseUI.unknown    => 'Unknown',
};

String phaseEmoji(CyclePhaseUI phase) => switch (phase) {
  CyclePhaseUI.menstrual  => '🌑',
  CyclePhaseUI.follicular => '🌒',
  CyclePhaseUI.ovulation  => '🌕',
  CyclePhaseUI.luteal     => '🌖',
  CyclePhaseUI.unknown    => '🌙',
};

enum CyclePhaseUI { menstrual, follicular, ovulation, luteal, unknown }

// ── Theme ────────────────────────────────────────────────────────────────────

ThemeData buildTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: IMoonColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:        IMoonColors.primary,
      secondary:      IMoonColors.secondary,
      surface:        IMoonColors.surface,
      onPrimary:      IMoonColors.bg,
      onSecondary:    IMoonColors.bg,
      onSurface:      IMoonColors.textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
      displayLarge:  GoogleFonts.outfit(color: IMoonColors.textPrimary, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.outfit(color: IMoonColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.outfit(color: IMoonColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium:   GoogleFonts.outfit(color: IMoonColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge:     GoogleFonts.outfit(color: IMoonColors.textPrimary, fontSize: 15),
      bodyMedium:    GoogleFonts.outfit(color: IMoonColors.textMuted,   fontSize: 13),
      labelLarge:    GoogleFonts.outfit(color: IMoonColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor:    IMoonColors.surface,
      elevation:          0,
      centerTitle:        true,
      titleTextStyle: GoogleFonts.outfit(
        color: IMoonColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: const IconThemeData(color: IMoonColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:        IMoonColors.surface,
      indicatorColor:         IMoonColors.primaryDim,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: IMoonColors.primary, size: 24);
        }
        return const IconThemeData(color: IMoonColors.textMuted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.outfit(color: IMoonColors.primary, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return GoogleFonts.outfit(color: IMoonColors.textMuted, fontSize: 11);
      }),
    ),
    cardTheme: CardThemeData(
      color:        IMoonColors.surface,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: IMoonColors.border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: IMoonColors.primary,
      foregroundColor: IMoonColors.bg,
    ),
    dividerColor: IMoonColors.border,
    dividerTheme: const DividerThemeData(color: IMoonColors.border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        IMoonColors.surfaceVar,
      border:           OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IMoonColors.border),
      ),
      enabledBorder:    OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IMoonColors.border),
      ),
      focusedBorder:    OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IMoonColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.outfit(color: IMoonColors.textDim, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: IMoonColors.primary,
        foregroundColor: IMoonColors.bg,
        minimumSize:     const Size.fromHeight(50),
        shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:       GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor:   IMoonColors.surfaceVar,
      selectedColor:     IMoonColors.primaryDim,
      labelStyle:        GoogleFonts.outfit(fontSize: 12, color: IMoonColors.textPrimary),
      side:              const BorderSide(color: IMoonColors.border),
      shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding:           const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
  );
}
