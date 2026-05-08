import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _kAccentColorKey = 'accent_color';

/// Injected at app startup — see main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) =>
      throw UnimplementedError(
        'Override sharedPreferencesProvider in ProviderScope',
      ),
);

/// Accent color used throughout the UI.
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs);
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier(this._prefs)
    : super(
        Color(
          _prefs.getInt(_kAccentColorKey) ?? AppTheme.defaultAccent.toARGB32(),
        ),
      );

  final SharedPreferences _prefs;

  void setColor(Color color) {
    state = color;
    _prefs.setInt(_kAccentColorKey, color.toARGB32());
  }
}
