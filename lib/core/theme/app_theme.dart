import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Obsidian Pulse — Electric Minimalism design system.
/// Surfaces follow the tonal-layer spec: 0→base, 1→cards, 2→floating.
class AppTheme {
  AppTheme._();

  // ── Tonal surface layers ────────────────────────────────────────────────
  /// Surface 0 — infinite canvas / scaffold background
  static const Color surface = Color(0xFF121212);

  /// Surface 1 — cards & containers (#1E1E1E)
  static const Color surfaceContainer = Color(0xFF1E1E1E);

  /// Surface 2 — floating / interactive elements (#2A2A2A)
  static const Color surface2 = Color(0xFF2A2A2A);

  // Legacy aliases kept so other files don't break
  static const Color dockSurface = surfaceContainer;
  static const Color iconSurface = surface2;
  static const Color pillSurface = surface2;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF808080);

  // ── Accent presets ──────────────────────────────────────────────────────
  /// Amber / Orange Pulse — primary action catalyst
  static const Color presetAmber = Color(0xFFFF5722);

  /// Monochromatic Stealth
  static const Color presetStealth = Color(0xFFFFFFFF);

  /// Midnight / Slate
  static const Color presetMidnight = Color(0xFF5C7AEA);

  /// Rose — vivid warm pink for AMOLED contrast
  static const Color presetRose = Color(0xFFFF4081);

  static const Color defaultAccent = presetAmber;

  static ThemeData dark(Color accent) {
    final colorScheme = ColorScheme.dark(
      surface: surface,
      surfaceContainer: surfaceContainer,
      primary: accent,
      secondary: accent,
      onSurface: textPrimary,
      onPrimary: Colors.white,
    );

    // Body + label text: Hanken Grotesk for legibility at small sizes
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.soraTextTheme(baseTextTheme)
        .copyWith(
          // bodyLarge / bodyMedium / bodySmall → Hanken Grotesk
          bodyLarge: GoogleFonts.hankenGrotesk(
            color: textPrimary,
            fontSize: 18,
            height: 1.55,
          ),
          bodyMedium: GoogleFonts.hankenGrotesk(
            color: textPrimary,
            fontSize: 16,
            height: 1.5,
          ),
          bodySmall: GoogleFonts.hankenGrotesk(
            color: textSecondary,
            fontSize: 12,
            height: 1.33,
          ),
          labelLarge: GoogleFonts.hankenGrotesk(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05 * 14,
          ),
          labelMedium: GoogleFonts.hankenGrotesk(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: GoogleFonts.hankenGrotesk(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        )
        .apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.white10,
    );
  }
}
