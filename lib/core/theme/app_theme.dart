import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Obsidian Pulse dark theme — pure black surface, configurable accent.
class AppTheme {
  AppTheme._();

  static const Color surface = Color(0xFF000000);
  static const Color surfaceContainer = Color(0xFF1A1A1A);
  static const Color dockSurface = Color(0xFF1A1A1A);
  static const Color iconSurface = Color(0xFF262626);
  static const Color pillSurface = Color(0xFF1C1C1C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF808080);

  // Named theme presets (Visual Variations — Section 5 of brief)
  /// Amber / Orange Pulse — vibrant energy
  static const Color presetAmber = Color(0xFFFF5722);

  /// Monochromatic Stealth — high-contrast minimal
  static const Color presetStealth = Color(0xFFFFFFFF);

  /// Midnight / Slate — nocturnal cool
  static const Color presetMidnight = Color(0xFF5C7AEA);

  static const Color defaultAccent = presetAmber;

  static ThemeData dark(Color accent) {
    final colorScheme = ColorScheme.dark(
      surface: surface,
      surfaceContainer: surfaceContainer,
      primary: accent,
      secondary: accent,
      onSurface: textPrimary,
      onPrimary: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.soraTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
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
