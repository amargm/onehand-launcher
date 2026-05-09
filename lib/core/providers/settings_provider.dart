import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _kAccentColorKey = 'accent_color';
const _kShowFolderLabels = 'show_folder_labels';
const _kShowSearchLabel = 'show_search_label';
const _kRightHanded = 'right_handed';

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

// ── Dock label visibility ──────────────────────────────────────────────────

/// Whether folder name labels are shown beneath dock buttons.
final showFolderLabelsProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kShowFolderLabels, defaultValue: true);
});

/// Whether the "Search" label is shown beneath the search button.
final showSearchLabelProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kShowSearchLabel, defaultValue: true);
});

class _BoolNotifier extends StateNotifier<bool> {
  _BoolNotifier(this._prefs, this._key, {required bool defaultValue})
    : super(_prefs.getBool(_key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  void toggle() => _set(!state);

  void set(bool value) => _set(value);

  void _set(bool value) {
    state = value;
    _prefs.setBool(_key, value);
  }
}

// ── Handedness ─────────────────────────────────────────────────────────────

/// `true` = right-handed (search rightmost, default).
/// `false` = left-handed (search leftmost).
final rightHandedProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kRightHanded, defaultValue: true);
});

// ── Clock format ───────────────────────────────────────────────────────────

const _kUse24HourClock = 'use_24_hour_clock';

/// `true` = 24-hour display (default). `false` = 12-hour (AM/PM).
final use24HourClockProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kUse24HourClock, defaultValue: true);
});

// ── Wallpaper ──────────────────────────────────────────────────────────────

const _kWallpaperPath = 'wallpaper_path';

/// Absolute path to the locally-saved wallpaper image, or `null` if none set.
final wallpaperPathProvider = StateNotifierProvider<_StringNotifier, String?>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _StringNotifier(prefs, _kWallpaperPath);
});

class _StringNotifier extends StateNotifier<String?> {
  _StringNotifier(this._prefs, this._key) : super(_prefs.getString(_key));

  final SharedPreferences _prefs;
  final String _key;

  void set(String path) {
    state = path;
    _prefs.setString(_key, path);
  }

  void clear() {
    state = null;
    _prefs.remove(_key);
  }
}
